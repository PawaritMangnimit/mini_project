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
