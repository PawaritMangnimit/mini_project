#!/usr/bin/env bash
set -euo pipefail

echo ">>> Reverting templates to old syntax (layout :: content) and restoring original SecurityConfig..."

# --- restore SecurityConfig (original package: com.example.uni.security) ---
mkdir -p src/main/java/com/example/uni/security
cat > src/main/java/com/example/uni/security/SecurityConfig.java <<'JAVA'
package com.example.uni.security;

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
                .requestMatchers("/", "/login", "/register", "/css/**").permitAll()
                .requestMatchers("/me/**").authenticated()
                .requestMatchers(HttpMethod.GET, "/jobs/new").hasRole("STAFF")
                .requestMatchers(HttpMethod.POST, "/jobs").hasRole("STAFF")
                .requestMatchers(HttpMethod.POST, "/jobs/*/apply").hasRole("STUDENT")
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/login")
                .permitAll()
                .defaultSuccessUrl("/", true)
            )
            .logout(logout -> logout.logoutUrl("/logout").logoutSuccessUrl("/"))
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

    // Prototype เท่านั้น — โปรดเปลี่ยนเป็น BCrypt ก่อนใช้งานจริง
    @Bean public PasswordEncoder passwordEncoder(){ return NoOpPasswordEncoder.getInstance(); }
}
JAVA

# --- restore templates to old fragment syntax (no ~{}) ---
cd src/main/resources/templates

# index.html
cat > index.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
<main class="container">
  <h1>ประกาศงาน/กิจกรรมล่าสุด</h1>
  <div class="cards" th:if="${#lists.isEmpty(jobs)}">
    <p>ยังไม่มีประกาศงาน</p>
  </div>
  <div class="cards" th:if="${!#lists.isEmpty(jobs)}">
    <div class="card" th:each="j : ${jobs}">
      <h3><a th:href="@{'/jobs/' + ${j.id}}" th:text="${j.title}">ชื่องาน</a></h3>
      <p th:text="${j.description.length() > 140 ? j.description.substring(0,140) + '...' : j.description}">รายละเอียด</p>
      <p><b>สถานที่:</b> <span th:text="${j.location}">ที่ตั้ง</span></p>
      <p><b>หมวด:</b> <span th:text="${j.category} ?: '-'">หมวด</span></p>
    </div>
  </div>
</main>
</html>
HTML

# login.html
cat > login.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
<main class="container">
  <h1>เข้าสู่ระบบ</h1>
  <form method="post" th:action="@{/login}">
    <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
    <label>อีเมล <input type="email" name="username" required/></label>
    <label>รหัสผ่าน <input type="password" name="password" required/></label>
    <button type="submit">เข้าสู่ระบบ</button>
  </form>
  <p>ทดสอบเร็วๆ: staff@uni.local / 123456 หรือ student@uni.local / 123456</p>
</main>
</html>
HTML

# register.html
cat > register.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
<main class="container">
  <h1>สมัครสมาชิก</h1>
  <p class="error" th:if="${error}" th:text="${error}"></p>
  <form method="post" th:action="@{/register}">
    <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
    <label>อีเมล <input type="email" name="email" required/></label>
    <label>ชื่อ-นามสกุล <input type="text" name="fullName" required/></label>
    <label>รหัสผ่าน <input type="password" name="password" required/></label>
    <label>บทบาท
      <select name="role" id="role-select" onchange="toggleStaffSecret()">
        <option value="STUDENT">นักศึกษา</option>
        <option value="STAFF">อาจารย์/บุคลากร</option>
      </select>
    </label>
    <div id="staff-secret" style="display:none;">
      <label>รหัสยืนยัน STAFF <input type="text" name="staffSecretInput" placeholder="ขอจากฝ่ายกิจการนิสิต"/></label>
    </div>
    <button type="submit">สมัคร</button>
  </form>
  <script>
    function toggleStaffSecret(){
      const role = document.getElementById('role-select').value;
      document.getElementById('staff-secret').style.display = role === 'STAFF' ? 'block' : 'none';
    }
    toggleStaffSecret();
  </script>
</main>
</html>
HTML

# job_form.html
cat > job_form.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
<main class="container">
  <h1>ลงประกาศงาน (STAFF)</h1>
  <form method="post" th:action="@{/jobs}">
    <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
    <label>ชื่องาน <input type="text" name="title" required/></label>
    <label>สถานที่ <input type="text" name="location" required/></label>
    <label>หมวดหมู่ <input type="text" name="category" placeholder="เช่น Volunteer, งาน Staff"/></label>
    <label>รายละเอียด
      <textarea name="description" rows="6" required></textarea>
    </label>
    <button type="submit">บันทึกประกาศ</button>
  </form>
</main>
</html>
HTML

# job_detail.html
cat > job_detail.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
<main class="container">
  <h1 th:text="${job.title}">งาน</h1>
  <p><b>สถานที่:</b> <span th:text="${job.location}">-</span></p>
  <p><b>หมวด:</b> <span th:text="${job.category} ?: '-'">-</span></p>
  <pre class="desc" th:text="${job.description}">รายละเอียด</pre>

  <div th:if="${isStudent}">
    <h2>สมัครเข้าร่วม</h2>
    <form method="post" th:action="@{'/jobs/' + ${job.id} + '/apply'}">
      <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
      <label>เหตุผล/แรงจูงใจ
        <textarea name="motivation" rows="4" required placeholder="เล่าเหตุผล/ประสบการณ์สั้นๆ"></textarea>
      </label>
      <button type="submit">ส่งใบสมัคร</button>
    </form>
  </div>

  <div th:if="${!isStudent}">
    <p><i>เฉพาะนักศึกษาที่เข้าสู่ระบบในบทบาท STUDENT จึงจะเห็นแบบฟอร์มสมัคร</i></p>
  </div>
</main>
</html>
HTML

# my_applications.html
cat > my_applications.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
<main class="container">
  <h1>การสมัครของฉัน</h1>
  <div class="cards" th:if="${#lists.isEmpty(apps)}">
    <p>ยังไม่มีการสมัคร</p>
  </div>
  <div class="cards" th:if="${!#lists.isEmpty(apps)}">
    <div class="card" th:each="a : ${apps}">
      <h3 th:text="${a.job.title}">งาน</h3>
      <p><b>สมัครเมื่อ:</b> <span th:text="${#temporals.format(a.createdAt, 'yyyy-MM-dd HH:mm')}">เวลา</span></p>
      <p><b>เหตุผล:</b></p>
      <pre class="desc" th:text="${a.motivation}">เหตุผล</pre>
    </div>
  </div>
</main>
</html>
HTML

# my_posted.html
cat > my_posted.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
<main class="container">
  <h1>งานที่ฉันสร้าง</h1>
  <div class="cards" th:if="${#lists.isEmpty(myjobs)}">
    <p>ยังไม่มีงานที่สร้าง</p>
  </div>
  <div class="cards" th:if="${!#lists.isEmpty(myjobs)}">
    <div class="card" th:each="j : ${myjobs}">
      <h3><a th:href="@{'/jobs/' + ${j.id}}" th:text="${j.title}">ชื่องาน</a></h3>
      <p th:text="${j.description.length() > 140 ? j.description.substring(0,140) + '...' : j.description}">รายละเอียด</p>
      <p><b>สถานที่:</b> <span th:text="${j.location}">ที่ตั้ง</span></p>
      <p><b>หมวด:</b> <span th:text="${j.category} ?: '-'">หมวด</span></p>
    </div>
  </div>
</main>
</html>
HTML

echo ">>> Revert done."
