package com.example.uni.web;

import com.example.uni.model.Job;
import com.example.uni.model.User;
import com.example.uni.repo.JobRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class JobController {

    private final JobRepository jobRepository;
    private final GlobalModelAttributes globals;

    public JobController(JobRepository jobRepository, GlobalModelAttributes globals) {
        this.jobRepository = jobRepository;
        this.globals = globals;
    }

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("jobs", jobRepository.findAllByOrderByCreatedAtDesc());
        return "index";
    }

    @GetMapping("/jobs/{id}")
    public String jobDetail(@PathVariable Long id, Model model) {
        Job job = jobRepository.findById(id).orElseThrow();
        model.addAttribute("job", job);
        return "job_detail";
    }

    @PreAuthorize("hasRole('STAFF')")
    @GetMapping("/jobs/new")
    public String newJobForm() {
        return "job_form";
    }

    @PreAuthorize("hasRole('STAFF')")
    @PostMapping("/jobs")
    public String createJob(
            @RequestParam String title,
            @RequestParam String description,
            @RequestParam String location,
            @RequestParam(required = false) String category
    ) {
        User me = globals.currentUser();
        Job j = new Job();
        j.setTitle(title);
        j.setDescription(description);
        j.setLocation(location);
        j.setCategory(category);
        j.setPostedBy(me);
        jobRepository.save(j);
        return "redirect:/me/posted";
    }

    @PreAuthorize("hasRole('STAFF')")
    @GetMapping("/me/posted")
    public String myPosted(Model model) {
        User me = globals.currentUser();
        model.addAttribute("myjobs", jobRepository.findByPostedByOrderByCreatedAtDesc(me));
        return "my_posted";
    }
}
