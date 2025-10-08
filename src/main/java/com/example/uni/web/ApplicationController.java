package com.example.uni.web;

import com.example.uni.model.Application;
import com.example.uni.model.Job;
import com.example.uni.model.User;
import com.example.uni.repo.ApplicationRepository;
import com.example.uni.repo.JobRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class ApplicationController {

    private final ApplicationRepository applicationRepository;
    private final JobRepository jobRepository;
    private final GlobalModelAttributes globals;

    public ApplicationController(ApplicationRepository ar, JobRepository jr, GlobalModelAttributes g) {
        this.applicationRepository = ar;
        this.jobRepository = jr;
        this.globals = g;
    }

    @PreAuthorize("hasRole('STUDENT')")
    @PostMapping("/jobs/{id}/apply")
    public String apply(@PathVariable Long id, @RequestParam String motivation) {
        Job job = jobRepository.findById(id).orElseThrow();
        User me = globals.currentUser();
        Application app = new Application();
        app.setJob(job);
        app.setStudent(me);
        app.setMotivation(motivation);
        applicationRepository.save(app);
        return "redirect:/me/applications";
    }

    @GetMapping("/me/applications")
    public String myApplications(Model model) {
        User me = globals.currentUser();
        if (me == null) return "redirect:/login";
        model.addAttribute("apps", applicationRepository.findByStudentOrderByCreatedAtDesc(me));
        return "my_applications";
    }
}
