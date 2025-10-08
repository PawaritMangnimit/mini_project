package com.example.uni.repo;

import com.example.uni.model.Application;
import com.example.uni.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ApplicationRepository extends JpaRepository<Application, Long> {
    List<Application> findByStudentOrderByCreatedAtDesc(User student);
    long countByJobId(Long jobId);
}
