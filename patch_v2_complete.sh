#!/usr/bin/env bash
set -euo pipefail

echo ">>> Patch: update pom.xml (bind repackage) + add full source & views"

# --- Ensure dirs ---
mkdir -p src/main/java/com/example/uni/{model,repo,security,web}
mkdir -p src/main/resources/{templates,static/css}

# --- POM with repackage execution ---
cat > pom.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>uni-activities</artifactId>
  <version>0.0.2-SNAPSHOT</version>
  <name>uni-activities</name>
  <description>University activities board (prototype)</description>

  <properties>
    <java.version>21</java.version>
    <spring-boot.version>3.3.4</spring-boot.version>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-dependencies</artifactId>
        <version>${spring-boot.version}</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-thymeleaf</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <version>${spring-boot.version}</version>
        <executions>
          <execution>
            <goals>
              <goal>repackage</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
EOF

# --- Application main ---
cat > src/main/java/com/example/uni/UniActivitiesApplication.java <<'EOF'
package com.example.uni;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class UniActivitiesApplication {
    public static void main(String[] args) {
        SpringApplication.run(UniActivitiesApplication.class, args);
    }
}
EOF

# --- Models ---
cat > src/main/java/com/example/uni/model/Role.java <<'EOF'
package com.example.uni.model;
public enum Role { STUDENT, STAFF }
EOF

cat > src/main/java/com/example/uni/model/User.java <<'EOF'
package com.example.uni.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

@Entity
@Table(name = "app_user")
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Email @NotBlank
    @Column(nullable = false, unique = true)
    private String email;

    @NotBlank
    private String password;

    @NotBlank
    private String fullName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    public Long getId() { return id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }
}
EOF

cat > src/main/java/com/example/uni/model/Job.java <<'EOF'
package com.example.uni.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDateTime;

@Entity @Table(name = "job")
public class Job {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank private String title;
    @NotBlank @Column(length = 4000) private String description;
    @NotBlank private String location;
    private String category;
    private LocalDateTime createdAt;

    @ManyToOne(optional = false) @JoinColumn(name = "posted_by_id")
    private User postedBy;

    @PrePersist public void prePersist(){ createdAt = LocalDateTime.now(); }

    public Long getId(){ return id; }
    public String getTitle(){ return title; }
    public void setTitle(String title){ this.title = title; }
    public String getDescription(){ return description; }
    public void setDescription(String description){ this.description = description; }
    public String getLocation(){ return location; }
    public void setLocation(String location){ this.location = location; }
    public String getCategory(){ return category; }
    public void setCategory(String category){ this.category = category; }
    public LocalDateTime getCreatedAt(){ return createdAt; }
    public User getPostedBy(){ return postedBy; }
    public void setPostedBy(User postedBy){ this.postedBy = postedBy; }
}
EOF

cat > src/main/java/com/example/uni/model/Application.java <<'EOF'
package com.example.uni.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDateTime;

@Entity @Table(name = "job_application")
public class Application {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional=false) @JoinColumn(name="job_id")
    private Job job;

    @ManyToOne(optional=false) @JoinColumn(name="student_id")
    private User student;

    @NotBlank @Column(length=4000)
    private String motivation;

    private LocalDateTime createdAt;
    @PrePersist public void prePersist(){ createdAt = LocalDateTime.now(); }

    public Long getId(){ return id; }
    public Job getJob(){ return job; }
    public void setJob(Job job){ this.job = job; }
    public User getStudent(){ return student; }
    public void setStudent(User student){ this.student = student; }
    public String getMotivation(){ return motivation; }
    public void setMotivation(String motivation){ this.motivation = motivation; }
    public LocalDateTime getCreatedAt(){ return createdAt; }
}
EOF

# --- Repos ---
cat > src/main/java/com/example/uni/repo/UserRepository.java <<'EOF'
package com.example.uni.repo;

import com.example.uni.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
EOF

cat > src/main/java/com/example/uni/repo/JobRepository.java <<'EOF'
package com.example.uni.repo;

import com.example.uni.model.Job;
import com.example.uni.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface JobRepository extends JpaRepository<Job, Long> {
    List<Job> findAllByOrderByCreatedAtDesc();
    List<Job> findByPostedByOrderByCreatedAtDesc(User postedBy);
}
EOF

cat > src/main/java/com/example/uni/repo/ApplicationRepository.java <<'EOF'
package com.example.uni.repo;

import com.example.uni.model.Application;
import com.example.uni.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ApplicationRepository extends JpaRepository<Application, Long> {
    List<Application> findByStudentOrderByCreatedAtDesc(User student);
    long countByJobId(Long jobId);
}
EOF

# --- Security ---
cat > src/main/java/com/example/uni/security/CustomUserDetails.java <<'EOF'
package com.example.uni.security;

import com.example.uni.model.User;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.List;

public class CustomUserDetails implements UserDetails {
    private final User user;
    public CustomUserDetails(User user){ this.user = user; }
    @Override public Collection<? extends GrantedAuthority> getAuthorities(){
        return List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()));
    }
    @Override public String getPassword(){ return user.getPassword(); }
    @Override public String getUsername(){ return user.getEmail(); }
    @Override public boolean isAccountNonExpired(){ return true; }
    @Override public boolean isAccountNonLocked(){ return true; }
    @Override public boolean isCredentialsNonExpired(){ return true; }
    @Override public boolean isEnabled(){ return true; }
    public User getUser(){ return user; }
}
EOF

cat > src/main/java/com/example/uni/security/CustomUserDetailsService.java <<'EOF'
package com.example.uni.security;

import com.example.uni.model.User;
import com.example.uni.repo.UserRepository;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService implements UserDetailsService {
    private final UserRepository userRepository;
    public CustomUserDetailsService(UserRepository userRepository){ this.userRepository = userRepository; }
    @Override
    public CustomUserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User u = userRepository.findByEmail(email).orElseThrow(() -> new UsernameNotFoundException("User not found"));
        return new CustomUserDetails(u);
    }
}
EOF

cat > src/main/java/com/example/uni/security/SecurityConfig.java <<'EOF'
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
            .formLogin(form -> form.loginPage("/login").permitAll().defaultSuccessUrl("/", true))
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
EOF

# --- Global model helpers ---
cat > src/main/java/com/example/uni/web/GlobalModelAttributes.java <<'EOF'
package com.example.uni.web;

import com.example.uni.model.User;
import com.example.uni.security.CustomUserDetails;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@Component
@ControllerAdvice
public class GlobalModelAttributes {

    @ModelAttribute("isAuthenticated")
    public boolean isAuthenticated() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.isAuthenticated() && !"anonymousUser".equals(a.getPrincipal());
    }

    @ModelAttribute("isStaff")
    public boolean isStaff() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.getAuthorities().stream().anyMatch(x -> "ROLE_STAFF".equals(x.getAuthority()));
    }

    @ModelAttribute("isStudent")
    public boolean isStudent() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.getAuthorities().stream().anyMatch(x -> "ROLE_STUDENT".equals(x.getAuthority()));
    }

    @ModelAttribute("currentUserName")
    public String currentUserName() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || "anonymousUser".equals(a.getPrincipal())) return null;
        if (a.getPrincipal() instanceof CustomUserDetails cud) return cud.getUser().getFullName();
        return a.getName();
    }

    public User currentUser() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || "anonymousUser".equals(a.getPrincipal())) return null;
        if (a.getPrincipal() instanceof CustomUserDetails cud) return cud.getUser();
        return null;
    }
}
EOF

# --- Controllers ---
cat > src/main/java/com/example/uni/web/AuthController.java <<'EOF'
package com.example.uni.web;

import com.example.uni.model.Role;
import com.example.uni.model.User;
import com.example.uni.repo.UserRepository;
import jakarta.validation.constraints.Email;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@Controller
@Validated
public class AuthController {

    private final UserRepository userRepository;

    @Value("${app.staff-register-secret}")
    private String staffSecret;

    public AuthController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/login")
    public String login(Authentication auth) {
        if (auth != null && !(auth instanceof AnonymousAuthenticationToken) && auth.isAuthenticated()) {
            return "redirect:/";
        }
        return "login";
    }

    @GetMapping("/register")
    public String registerForm(Model model) {
        model.addAttribute("error", null);
        return "register";
    }

    @PostMapping("/register")
    public String register(
            @RequestParam @Email String email,
            @RequestParam String fullName,
            @RequestParam String password,
            @RequestParam String role,
            @RequestParam(required = false) String staffSecretInput,
            Model model
    ) {
        if (userRepository.findByEmail(email).isPresent()) {
            model.addAttribute("error", "อีเมลนี้ถูกใช้แล้ว");
            return "register";
        }

        Role r;
        try { r = Role.valueOf(role); }
        catch (Exception e) {
            model.addAttribute("error", "บทบาทไม่ถูกต้อง");
            return "register";
        }

        if (r == Role.STAFF) {
            if (staffSecretInput == null || !staffSecretInput.equals(staffSecret)) {
                model.addAttribute("error", "รหัสยืนยัน STAFF ไม่ถูกต้อง");
                return "register";
            }
        }

        User u = new User();
        u.setEmail(email);
        u.setFullName(fullName);
        u.setPassword(password); // Prototype: NoOp
        u.setRole(r);
        userRepository.save(u);

        return "redirect:/login";
    }
}
EOF

cat > src/main/java/com/example/uni/web/JobController.java <<'EOF'
package com.example.uni.web;

import com.example.uni.model.Job;
import com.example.uni.model.User;
import com.example.uni.repo.JobRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class JobController {

    private final JobRepository jobRepository;
    private final GlobalModelAttributes globals;

    public JobController(JobRepository jobRepository, GlobalModelAttributes globals) {
        this.jobRepository = jobRepository;
        this.globals = globals;
    }

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("jobs", jobRepository.findAllByOrderByCreatedAtDesc());
        return "index";
    }

    @GetMapping("/jobs/{id}")
    public String jobDetail(@PathVariable Long id, Model model) {
        Job job = jobRepository.findById(id).orElseThrow();
        model.addAttribute("job", job);
        return "job_detail";
    }

    @PreAuthorize("hasRole('STAFF')")
    @GetMapping("/jobs/new")
    public String newJobForm() {
        return "job_form";
    }

    @PreAuthorize("hasRole('STAFF')")
    @PostMapping("/jobs")
    public String createJob(
            @RequestParam String title,
            @RequestParam String description,
            @RequestParam String location,
            @RequestParam(required = false) String category
    ) {
        User me = globals.currentUser();
        Job j = new Job();
        j.setTitle(title);
        j.setDescription(description);
        j.setLocation(location);
        j.setCategory(category);
        j.setPostedBy(me);
        jobRepository.save(j);
        return "redirect:/me/posted";
    }

    @PreAuthorize("hasRole('STAFF')")
    @GetMapping("/me/posted")
    public String myPosted(Model model) {
        User me = globals.currentUser();
        model.addAttribute("myjobs", jobRepository.findByPostedByOrderByCreatedAtDesc(me));
        return "my_posted";
    }
}
EOF

cat > src/main/java/com/example/uni/web/ApplicationController.java <<'EOF'
package com.example.uni.web;

import com.example.uni.model.Application;
import com.example.uni.model.Job;
import com.example.uni.model.User;
import com.example.uni.repo.ApplicationRepository;
import com.example.uni.repo.JobRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class ApplicationController {

    private final ApplicationRepository applicationRepository;
    private final JobRepository jobRepository;
    private final GlobalModelAttributes globals;

    public ApplicationController(ApplicationRepository ar, JobRepository jr, GlobalModelAttributes g) {
        this.applicationRepository = ar;
        this.jobRepository = jr;
        this.globals = g;
    }

    @PreAuthorize("hasRole('STUDENT')")
    @PostMapping("/jobs/{id}/apply")
    public String apply(@PathVariable Long id, @RequestParam String motivation) {
        Job job = jobRepository.findById(id).orElseThrow();
        User me = globals.currentUser();
        Application app = new Application();
        app.setJob(job);
        app.setStudent(me);
        app.setMotivation(motivation);
        applicationRepository.save(app);
        return "redirect:/me/applications";
    }

    @GetMapping("/me/applications")
    public String myApplications(Model model) {
        User me = globals.currentUser();
        if (me == null) return "redirect:/login";
        model.addAttribute("apps", applicationRepository.findByStudentOrderByCreatedAtDesc(me));
        return "my_applications";
    }
}
EOF

# --- DataLoader seed ---
cat > src/main/java/com/example/uni/DataLoader.java <<'EOF'
package com.example.uni;

import com.example.uni.model.Job;
import com.example.uni.model.Role;
import com.example.uni.model.User;
import com.example.uni.repo.JobRepository;
import com.example.uni.repo.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class DataLoader implements CommandLineRunner {

    private final UserRepository userRepo;
    private final JobRepository jobRepo;

    public DataLoader(UserRepository userRepo, JobRepository jobRepo) {
        this.userRepo = userRepo;
        this.jobRepo = jobRepo;
    }

    @Override
    public void run(String... args) {
        User staff = userRepo.findByEmail("staff@uni.local").orElseGet(() -> {
            User u = new User();
            u.setEmail("staff@uni.local");
            u.setFullName("Prof. Staff");
            u.setPassword("123456");
            u.setRole(Role.STAFF);
            return userRepo.save(u);
        });

        userRepo.findByEmail("student@uni.local").orElseGet(() -> {
            User u = new User();
            u.setEmail("student@uni.local");
            u.setFullName("Student One");
            u.setPassword("123456");
            u.setRole(Role.STUDENT);
            return userRepo.save(u);
        });

        if (jobRepo.count() == 0) {
            Job j1 = new Job();
            j1.setTitle("Staff งานรับน้องคณะ");
            j1.setDescription("ช่วยต้อนรับน้องใหม่ หน้าที่: จัดเก้าอี้, จัดคิวขึ้นเวที");
            j1.setLocation("อาคารกิจกรรมนักศึกษา");
            j1.setCategory("งานอาสา");
            j1.setPostedBy(staff);
            jobRepo.save(j1);

            Job j2 = new Job();
            j2.setTitle("อาสาสมัครงานวิ่งมหาลัย");
            j2.setDescription("แจกน้ำ, เช็คจุดบริการ, ประสานงานกับทีมแพทย์");
            j2.setLocation("สนามกีฬา");
            j2.setCategory("Volunteer");
            j2.setPostedBy(staff);
            jobRepo.save(j2);
        }
    }
}
EOF

# --- Templates ---
cat > src/main/resources/templates/layout.html <<'EOF'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <title th:text="${title} ?: 'Uni Activities'">Uni Activities</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
</head>
<body>
<header class="topbar">
  <div class="container">
    <a class="brand" th:href="@{/}">Uni Activities</a>
    <nav>
      <span th:if="${isAuthenticated}">
        สวัสดี, <b th:text="${currentUserName}">User</b>
        <a th:if="${isStaff}" th:href="@{/jobs/new}">ลงประกาศงาน</a>
        <a th:if="${isStaff}" th:href="@{/me/posted}">งานที่ฉันสร้าง</a>
        <a th:if="${isStudent}" th:href="@{/me/applications}">การสมัครของฉัน</a>
        <a th:href="@{/logout}">ออกจากระบบ</a>
      </span>
      <span th:if="${!isAuthenticated}">
        <a th:href="@{/login}">เข้าสู่ระบบ</a>
        <a th:href="@{/register}">สมัครสมาชิก</a>
      </span>
    </nav>
  </div>
</header>

<main class="container" th:fragment="content">
  <div>Content</div>
</main>

<footer class="footer">
  <div class="container">
    <small>Prototype • Spring Boot + Docker • สำหรับใช้งานภายในมหาลัย</small>
  </div>
</footer>
</body>
</html>
EOF

cat > src/main/resources/templates/index.html <<'EOF'
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
EOF

cat > src/main/resources/templates/login.html <<'EOF'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
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
EOF

cat > src/main/resources/templates/register.html <<'EOF'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
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
EOF

cat > src/main/resources/templates/job_form.html <<'EOF'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
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
EOF

cat > src/main/resources/templates/job_detail.html <<'EOF'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
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
EOF

cat > src/main/resources/templates/my_applications.html <<'EOF'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
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
EOF

cat > src/main/resources/templates/my_posted.html <<'EOF'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org" th:replace="layout :: content">
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
EOF

# --- CSS ---
cat > src/main/resources/static/css/main.css <<'EOF'
:root { --bg:#f7f7fb; --fg:#222; --card:#fff; --brand:#2a5bd7; }
* { box-sizing:border-box; font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
body { margin:0; color:var(--fg); background:var(--bg); }
.container { max-width: 960px; margin: 0 auto; padding: 16px; }
.topbar { background:#fff; border-bottom:1px solid #eee; }
.topbar .brand { font-weight:700; color:var(--brand); text-decoration:none; margin-right:16px; }
.topbar nav a { margin-left:12px; text-decoration:none; color:#333; }
h1,h2,h3 { margin: 8px 0 12px; }
label { display:block; margin: 8px 0; }
input[type=text],input[type=email],input[type=password],textarea,select {
  width:100%; padding:10px; border:1px solid #ddd; border-radius:8px; background:#fff;
}
button { padding:10px 14px; border:0; border-radius:10px; background:var(--brand); color:#fff; cursor:pointer; }
.cards { display:grid; gap:12px; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); }
.card { background:var(--card); border:1px solid #eee; border-radius:12px; padding:16px; }
pre.desc { white-space: pre-wrap; background:#fafafa; padding:12px; border-radius:8px; border:1px solid #eee; }
.error { color:#c00; }
.footer { color:#555; padding:16px 0; }
EOF

echo ">>> Patch complete."
