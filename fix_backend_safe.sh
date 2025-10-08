#!/bin/bash
set -e

echo "��� กำลังสร้าง repository, service และ DataSeeder..."

# ----- Repository -----
mkdir -p src/main/java/com/example/uni/repository

cat > src/main/java/com/example/uni/repository/UserRepository.java <<'EOF'
package com.example.uni.repository;

import com.example.uni.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
EOF

cat > src/main/java/com/example/uni/repository/JobRepository.java <<'EOF'
package com.example.uni.repository;

import com.example.uni.model.Job;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JobRepository extends JpaRepository<Job, Long> {
}
EOF

# ----- Service -----
mkdir -p src/main/java/com/example/uni/service

cat > src/main/java/com/example/uni/service/CustomUserDetailsService.java <<'EOF'
package com.example.uni.service;

import com.example.uni.model.User;
import com.example.uni.repository.UserRepository;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository repo;

    public CustomUserDetailsService(UserRepository repo) {
        this.repo = repo;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = repo.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("ไม่พบ user: " + email));

        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getEmail())
                .password(user.getPassword())
                .roles(user.getRole().name())
                .build();
    }
}
EOF

# ----- Seeder -----
mkdir -p src/main/java/com/example/uni/bootstrap

cat > src/main/java/com/example/uni/bootstrap/DataSeeder.java <<'EOF'
package com.example.uni.bootstrap;

import com.example.uni.model.User;
import com.example.uni.model.Role;
import com.example.uni.model.Job;
import com.example.uni.repository.UserRepository;
import com.example.uni.repository.JobRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Component;

@Component
public class DataSeeder {
    private final UserRepository users;
    private final JobRepository jobs;

    public DataSeeder(UserRepository users, JobRepository jobs) {
        this.users = users;
        this.jobs = jobs;
    }

    @PostConstruct
    public void seed() {
        if (users.count() == 0) {
            users.save(new User(null, "staff1@uni.local", "Staff One", "123456", Role.STAFF));
            users.save(new User(null, "staff2@uni.local", "Staff Two", "123456", Role.STAFF));
            users.save(new User(null, "student1@uni.local", "Student One", "123456", Role.STUDENT));
            users.save(new User(null, "student2@uni.local", "Student Two", "123456", Role.STUDENT));
        }
    }
}
EOF

echo "✅ เสร็จแล้ว: repositories + service + DataSeeder ถูกสร้างใหม่เรียบร้อย"
