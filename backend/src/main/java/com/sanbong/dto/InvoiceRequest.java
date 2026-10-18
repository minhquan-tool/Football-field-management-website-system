package com.sanbong.dto;
import jakarta.validation.constraints.Size;
public record InvoiceRequest(@Size(max=10) String maKM,Boolean daXacMinhDieuKien) { }
