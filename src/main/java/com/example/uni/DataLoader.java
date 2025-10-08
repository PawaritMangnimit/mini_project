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
