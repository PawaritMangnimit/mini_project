package com.example.uni.web;

import com.example.uni.model.User;
import com.example.uni.security.CustomUserDetails;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@Component
@ControllerAdvice
public class GlobalModelAttributes {

    @ModelAttribute("isAuthenticated")
    public boolean isAuthenticated() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.isAuthenticated() && !"anonymousUser".equals(a.getPrincipal());
    }

    @ModelAttribute("isStaff")
    public boolean isStaff() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.getAuthorities().stream().anyMatch(x -> "ROLE_STAFF".equals(x.getAuthority()));
    }

    @ModelAttribute("isStudent")
    public boolean isStudent() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.getAuthorities().stream().anyMatch(x -> "ROLE_STUDENT".equals(x.getAuthority()));
    }

    @ModelAttribute("currentUserName")
    public String currentUserName() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || "anonymousUser".equals(a.getPrincipal())) return null;
        if (a.getPrincipal() instanceof CustomUserDetails cud) return cud.getUser().getFullName();
        return a.getName();
    }

    public User currentUser() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || "anonymousUser".equals(a.getPrincipal())) return null;
        if (a.getPrincipal() instanceof CustomUserDetails cud) return cud.getUser();
        return null;
    }
}
