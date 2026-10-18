package com.sanbong.dto;
import jakarta.validation.constraints.*;
import java.util.Map;
public record ReviewRequest(@NotNull @Size(min=1,max=30) Map<@NotBlank String,@NotNull @Min(1) @Max(5) Integer> diem,
                            @Size(max=500) String noiDung) {}
