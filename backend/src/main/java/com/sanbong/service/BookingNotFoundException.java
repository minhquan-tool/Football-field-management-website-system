package com.sanbong.service;
public class BookingNotFoundException extends RuntimeException {
    public BookingNotFoundException(String message) { super(message); }
}
