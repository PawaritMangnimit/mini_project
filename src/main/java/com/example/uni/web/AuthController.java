package com.example.uni.web;

import com.example.uni.model.Role;
import com.example.uni.model.User;
import com.example.uni.repo.UserRepository;
import jakarta.validation.constraints.Email;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@Controller
@Validated
public class AuthController {

    private final UserRepository userRepository;

    @Value("${app.staff-register-secret}")
    private String staffSecret;

    public AuthController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/login")
    public String login(Authentication auth) {
        if (auth != null && !(auth instanceof AnonymousAuthenticationToken) && auth.isAuthenticated()) {
            return "redirect:/";
        }
        return "login";
    }

    @GetMapping("/register")
    public String registerForm(Model model) {
        model.addAttribute("error", null);
        return "register";
    }

    @PostMapping("/register")
    public String register(
            @RequestParam @Email String email,
            @RequestParam String fullName,
            @RequestParam String password,
            @RequestParam String role,
            @RequestParam(required = false) String staffSecretInput,
            Model model
    ) {
        if (userRepository.findByEmail(email).isPresent()) {
            model.addAttribute("error", "อีเมลนี้ถูกใช้แล้ว");
            return "register";
        }

        Role r;
        try { r = Role.valueOf(role); }
        catch (Exception e) {
            model.addAttribute("error", "บทบาทไม่ถูกต้อง");
            return "register";
        }

        if (r == Role.STAFF) {
            if (staffSecretInput == null || !staffSecretInput.equals(staffSecret)) {
                model.addAttribute("error", "รหัสยืนยัน STAFF ไม่ถูกต้อง");
                return "register";
            }
        }

        User u = new User();
        u.setEmail(email);
        u.setFullName(fullName);
        u.setPassword(password); // Prototype: NoOp
        u.setRole(r);
        userRepository.save(u);

        return "redirect:/login";
    }
}
