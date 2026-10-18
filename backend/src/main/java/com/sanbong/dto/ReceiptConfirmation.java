package com.sanbong.dto;
import jakarta.validation.constraints.*;
public record ReceiptConfirmation(@NotNull @AssertTrue Boolean daNhanTien) { }
