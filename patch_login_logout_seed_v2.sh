#!/usr/bin/env bash
set -euo pipefail

echo ">>> Fix logout 404 + add /login view + keep logout -> /, and ensure seed users"

BASE_JAVA="src/main/java/com/example/uni"

# --- เลือกไฟล์ SecurityConfig ที่มีอยู่ (หรือสร้างใหม่ใน package เดิมของโปรเจกต์) ---
if [ -f "$BASE_JAVA/security/SecurityConfig.java" ]; then
  TARGET="$BASE_JAVA/security/SecurityConfig.java"
  PKG="com.example.uni.security"
elif [ -f "$BASE_JAVA/config/SecurityConfig.java" ]; then
  TARGET="$BASE_JAVA/config/SecurityConfig.java"
  PKG="com.example.uni.config"
else
  mkdir -p "$BASE_JAVA/security"
  TARGET="$BASE_JAVA/security/SecurityConfig.java"
  PKG="com.example.uni.security"
fi

# --- เขียน SecurityConfig ให้ logout กลับหน้า "/" และเปิด /login, /register, /css ---
cat > "$TARGET" <<JAVA
package $PKG;

import com.example.uni.service.CustomUserDetailsService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final CustomUserDetailsService uds;

    public SecurityConfig(CustomUserDetailsService uds){ this.uds = uds; }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/index", "/login", "/register", "/css/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/jobs/new").hasRole("STAFF")
                .requestMatchers(HttpMethod.POST, "/jobs").hasRole("STAFF")
                .requestMatchers(HttpMethod.POST, "/jobs/*/apply").hasRole("STUDENT")
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/login")
                .defaultSuccessUrl("/", true)
                .permitAll()
            )
            .logout(logout -> logout
                .logoutUrl("/logout")
                .logoutSuccessUrl("/")
                .permitAll()
            )
            .csrf(Customizer.withDefaults());
        return http.build();
    }

    @Bean
    public DaoAuthenticationProvider authProvider(PasswordEncoder encoder){
        var p = new DaoAuthenticationProvider();
        p.setUserDetailsService(uds);
        p.setPasswordEncoder(encoder);
        return p;
    }

    // โปรโตไทป์เท่านั้น — เปลี่ยนเป็น BCrypt ตอนโปรดักชัน
    @Bean
    public PasswordEncoder passwordEncoder(){
        return NoOpPasswordEncoder.getInstance();
    }
}
JAVA
echo ">>> Wrote SecurityConfig at $TARGET"

# --- Map /login -> login.html ด้วย WebMvcConfigurer (ไม่ต้องมี Controller เต็มตัว) ---
mkdir -p "$BASE_JAVA/web"
cat > "$BASE_JAVA/web/WebMvcConfig.java" <<'JAVA'
package com.example.uni.web;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/login").setViewName("login");
    }
}
JAVA
echo ">>> Added WebMvcConfig mapping /login -> login.html"

# --- สร้าง/ทับ login.html (มีข้อความตอน logout แล้ว) ---
TPL="src/main/resources/templates"
mkdir -p "$TPL"
cat > "$TPL/login.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <title>เข้าสู่ระบบ</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
  <div th:replace="~{layout :: header}"></div>
  <main class="container">
    <h1>เข้าสู่ระบบ</h1>
    <form th:action="@{/login}" method="post">
      <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
      <label>อีเมล <input type="email" name="username" required/></label>
      <label>รหัสผ่าน <input type="password" name="password" required/></label>
      <button type="submit">เข้าสู่ระบบ</button>
    </form>
    <p th:if="${param.logout}" style="color:green;">ออกจากระบบสำเร็จแล้ว</p>
    <p th:if="${param.error}" style="color:red;">อีเมลหรือรหัสผ่านไม่ถูกต้อง</p>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML
echo ">>> Wrote login.html"

# --- แทนที่ลิงก์ logout (GET) ให้เป็นปุ่ม POST + CSRF ใน layout.html ถ้ายังไม่ได้ทำ ---
LAYOUT_FILE="$TPL/layout.html"
if [ -f "$LAYOUT_FILE" ]; then
  if grep -q 'th:href="@{/logout}"' "$LAYOUT_FILE"; then
    tmp="$LAYOUT_FILE.tmp"
    awk '
      BEGIN{done=0}
      {
        if ($0 ~ /th:href="@\{\/logout\}"/ && !done) {
          print "        <form th:action=\"@{/logout}\" method=\"post\" style=\"display:inline; margin-left:8px;\">";
          print "          <input type=\"hidden\" th:name=\"${_csrf.parameterName}\" th:value=\"${_csrf.token}\"/>";
          print "          <button type=\"submit\" style=\"background:none;border:none;color:#06c;cursor:pointer;padding:0;\">ออกจากระบบ</button>";
          print "        </form>";
          done=1;
        } else {
          print $0;
        }
      }' "$LAYOUT_FILE" > "$tmp" && mv "$tmp" "$LAYOUT_FILE"
    echo ">>> Replaced logout link with POST form in layout.html"
  else
    echo ">>> layout.html already has logout form (skip)"
  fi
else
  echo "WARN: $LAYOUT_FILE not found; skip logout form patch"
fi

# --- Seeder: สร้างผู้ใช้ STAFF 2 คน + STUDENT 2 คน (ถ้ายังไม่มี) ---
SEEDER="src/main/java/com/example/uni/bootstrap/DataSeeder.java"
mkdir -p "$(dirname "$SEEDER")"
cat > "$SEEDER" <<'JAVA'
package com.example.uni.bootstrap;

import com.example.uni.model.AppUser;
import com.example.uni.model.Role;
import com.example.uni.model.Job;
import com.example.uni.repository.AppUserRepository;
import com.example.uni.repository.JobRepository;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Component
public class DataSeeder implements ApplicationRunner {

    private final AppUserRepository users;
    private final JobRepository jobs;

    public DataSeeder(AppUserRepository users, JobRepository jobs) {
        this.users = users;
        this.jobs = jobs;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        ensureUser("staff1@uni.local", "Staff One", "123456", Role.STAFF);
        ensureUser("staff2@uni.local", "Staff Two", "123456", Role.STAFF);
        ensureUser("student1@uni.local", "Student One", "123456", Role.STUDENT);
        ensureUser("student2@uni.local", "Student Two", "123456", Role.STUDENT);

        if (jobs.count() == 0) {
            AppUser staff1 = users.findByEmail("staff1@uni.local").orElseThrow();
            Job j1 = new Job();
            j1.setTitle("อาสาสมัครงานปฐมนิเทศ");
            j1.setDescription("ช่วยเป็นสตาฟท์ลงทะเบียนและดูแลนิสิตใหม่ รอบเช้า");
            j1.setLocation("อาคารกิจกรรมนักศึกษา");
            j1.setCategory("Volunteer");
            j1.setPostedBy(staff1);
            j1.setCreatedAt(LocalDateTime.now().minusDays(1));
            jobs.save(j1);

            Job j2 = new Job();
            j2.setTitle("ผู้ช่วยงานสัมมนาวิชาการ");
            j2.setDescription("ดูแลเครื่องคอมและไมค์ในห้องสัมมนา | ต้องมา brief ล่วงหน้า 1 วัน");
            j2.setLocation("หอประชุมกลาง");
            j2.setCategory("Staff");
            j2.setPostedBy(staff1);
            j2.setCreatedAt(LocalDateTime.now().minusHours(6));
            jobs.save(j2);
        }
    }

    private void ensureUser(String email, String name, String rawPass, Role role) {
        Optional<AppUser> existing = users.findByEmail(email);
        if (existing.isEmpty()) {
            AppUser u = new AppUser();
            u.setEmail(email);
            u.setFullName(name);
            u.setPassword(rawPass); // โปรโตไทป์: NoOpPasswordEncoder
            u.setRole(role);
            users.save(u);
        }
    }
}
JAVA
echo ">>> Wrote DataSeeder"

echo ">>> Patch complete."
