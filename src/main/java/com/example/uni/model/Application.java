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
