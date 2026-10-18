package com.sanbong.service;
/** Distinct exception avoids Spring repository IllegalStateException translation. */
public class AmbiguousServiceLineException extends RuntimeException {
 public AmbiguousServiceLineException() { super("Có nhiều dòng cùng SKU; hãy thao tác bằng MaChiTiet."); }
}
