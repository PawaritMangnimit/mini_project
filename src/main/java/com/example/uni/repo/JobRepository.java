package com.example.uni.repo;

import com.example.uni.model.Job;
import com.example.uni.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface JobRepository extends JpaRepository<Job, Long> {
    List<Job> findAllByOrderByCreatedAtDesc();
    List<Job> findByPostedByOrderByCreatedAtDesc(User postedBy);
}
