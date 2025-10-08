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
