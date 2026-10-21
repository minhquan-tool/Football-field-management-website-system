package com.sanbong.controller;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {
    @GetMapping({"/","/api","/api/"})
    public String home() { return "redirect:/trang-chu"; }
}
