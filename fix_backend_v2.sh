cat > fix_backend_v2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo ">>> Start fixing backend (DataSeeder + SecurityConfig)"

BASE_JAVA="src/main/java/com/example/uni"

# --- Repository ---
mkdir -p "$BASE_JAVA/repository"
cat > "$BASE_JAVA/repository/UserRepository.java" <<'JAVA'
package com.example.uni.repository;

import com.example.uni.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
JAVA
echo ">>> UserRepository.java created"

# --- DataSeeder ---
mkdir -p "$BASE_JAVA/bootstrap"
cat > "$BASE_JAVA/bootstrap/DataSeeder.java" <<'JAVA'
package com.example.uni.bootstrap;

import com.example.uni.model.User;
import com.example.uni.model.Role;
import com.example.uni.repository.UserRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataSeeder {
    private final UserRepository users;
    private final PasswordEncoder encoder;

    public DataSeeder(UserRepository users, PasswordEncoder encoder) {
        this.users = users;
        this.encoder = encoder;
    }

    @PostConstruct
    public void seed() {
        if (users.count() == 0) {
            users.save(new User(null, "staff1@uni.local", "Staff One", encoder.encode("123456"), Role.STAFF));
            users.save(new User(null, "staff2@uni.local", "Staff Two", encoder.encode("123456"), Role.STAFF));
            users.save(new User(null, "student1@uni.local", "Student One", encoder.encode("123456"), Role.STUDENT));
            users.save(new User(null, "student2@uni.local", "Student Two", encoder.encode("123456"), Role.STUDENT));
        }
    }
}
JAVA
echo ">>> DataSeeder.java created"

# --- SecurityConfig ---
mkdir -p "$BASE_JAVA/security"
cat > "$BASE_JAVA/security/SecurityConfig.java" <<'JAVA'
package com.example.uni.security;

import com.example.uni.repository.UserRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final UserRepository userRepo;

    public SecurityConfig(UserRepository userRepo) {
        this.userRepo = userRepo;
    }

    @Bean
    public UserDetailsService userDetailsService() {
        return email -> userRepo.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/login", "/css/**").permitAll()
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/login").permitAll()
            )
            .logout(logout -> logout
                .logoutUrl("/logout")
                .logoutSuccessUrl("/")
                .permitAll()
            )
            .csrf(csrf -> csrf.disable()); // ปิด CSRF เพื่อให้ง่ายขึ้น

        return http.build();
    }

    @Bean
    public DaoAuthenticationProvider authProvider(PasswordEncoder encoder){
        var p = new DaoAuthenticationProvider();
        p.setUserDetailsService(userDetailsService());
        p.setPasswordEncoder(encoder);
        return p;
    }

    @Bean
    public PasswordEncoder passwordEncoder(){
        return new BCryptPasswordEncoder();
    }
}
JAVA
echo ">>> SecurityConfig.java created/updated"

echo ">>> Backend fix complete!"
EOF
