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
