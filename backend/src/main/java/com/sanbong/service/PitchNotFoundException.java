package com.sanbong.service;
public class PitchNotFoundException extends RuntimeException {
    public PitchNotFoundException() { super("Sân không tồn tại."); }
}
