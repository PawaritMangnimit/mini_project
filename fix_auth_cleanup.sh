#!/usr/bin/env bash
set -euo pipefail

echo ">>> 1) Remove duplicate SecurityConfig (keep only com.example.uni.security.SecurityConfig)"
BASE="src/main/java/com/example/uni"
KEEP="$BASE/security/SecurityConfig.java"

# ลบ SecurityConfig อื่น ๆ ที่ไม่ใช่ตัวหลัก
if [ -d "$BASE/config" ]; then
  find "$BASE/config" -maxdepth 1 -name "SecurityConfig.java" -print -exec rm -f {} \;
fi

mkdir -p "$BASE/security"
cat > "$KEEP" <<'JAVA'
package com.example.uni.security;

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
                .loginProcessingUrl("/login")
                .defaultSuccessUrl("/", true)
                .failureUrl("/login?error")
                .permitAll()
            )
            .logout(logout -> logout
                .logoutUrl("/logout")          // ใช้ POST (ค่าปริยาย) + CSRF
                .logoutSuccessUrl("/")         // ออกแล้วกลับหน้าแรก
                .clearAuthentication(true)
                .invalidateHttpSession(true)
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

    // โปรโตไทป์เท่านั้น: เก็บรหัสผ่านเป็น plain (อย่าทำในโปรดักชัน)
    @Bean
    public PasswordEncoder passwordEncoder(){
        return NoOpPasswordEncoder.getInstance();
    }
}
JAVA
echo ">>> SecurityConfig written: $KEEP"

echo ">>> 2) Map /login -> login.html (ถ้ายังไม่มี)"
mkdir -p "$BASE/web"
cat > "$BASE/web/WebMvcConfig.java" <<'JAVA'
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

echo ">>> 3) Add whoami controller for quick debug"
cat > "$BASE/web/WhoAmIController.java" <<'JAVA'
package com.example.uni.web;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class WhoAmIController {
    @GetMapping("/whoami")
    @ResponseBody
    public String whoami(Authentication auth){
        if (auth == null) return "anonymous";
        return "user=" + auth.getName() + ", authorities=" + auth.getAuthorities();
    }
}
JAVA

echo ">>> 4) Ensure login.html exists (แบบเรียบง่าย + แสดงข้อความ error/logout)"
TPL="src/main/resources/templates"
mkdir -p "$TPL"
cat > "$TPL/login.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.thymeleaf.org">
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
    <p><a href="/" >กลับหน้าแรก</a></p>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML

echo ">>> 5) Replace logout link with POST form (ถ้ายังเจอเป็นลิงก์)"
LAYOUT="$TPL/layout.html"
if [ -f "$LAYOUT" ] && grep -q 'th:href="@{/logout}"' "$LAYOUT"; then
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
    }' "$LAYOUT" > "$LAYOUT.tmp" && mv "$LAYOUT.tmp" "$LAYOUT"
  echo ">>> layout.html patched to POST logout"
else
  echo ">>> layout.html already OK or missing (skip)"
fi

echo ">>> 6) Turn on Spring Security DEBUG logging"
APP="src/main/resources/application.properties"
mkdir -p "$(dirname "$APP")"
grep -q '^logging.level.org.springframework.security=' "$APP" 2>/dev/null || echo 'logging.level.org.springframework.security=DEBUG' >> "$APP"

echo ">>> Done. Now rebuild."
