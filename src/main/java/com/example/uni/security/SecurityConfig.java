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
