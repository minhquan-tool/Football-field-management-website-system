package com.sanbong.controller;
import com.sanbong.config.AccountPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.core.io.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.*;

@Controller
public class PageController {
 public static final Map<String,String> PAGES=Map.ofEntries(
  Map.entry("phan-hoi","Phan_hoi.html"),Map.entry("trang-chu","Trang_chu.html"),Map.entry("dang-nhap","Dang_nhap.html"),Map.entry("dang-ky","Dang_ky.html"),
  Map.entry("khach-hang","Man_hinh_chinh_KH.html"),Map.entry("dat-san","Man_hinh_chinh_Dat_san_KH.html"),
  Map.entry("lich-dat-cua-toi","Quan_ly_lich_dat_san.html"),Map.entry("dieu-phoi-san","Quan_ly_lich_dat_san.html"),
  Map.entry("lich-su-dat-san","Man_hinh_LS&ĐG_KH.html"),Map.entry("khuyen-mai","Man_hinh_Khuyen_mai_KH.html"),Map.entry("tai-khoan","Tai_khoan_KH.html"),
  Map.entry("nhan-vien","Man_hinh_chinh_NVKH.html"),Map.entry("lich-san","Lich_da_bong.html"),Map.entry("dat-san-tai-quay","Dat_san_tai_quay.html"),Map.entry("quan-ly-san","Quan_ly_san.html"),
  Map.entry("hoa-don","Man_hinh_chinh_NVKT.html"),Map.entry("hoan-tien","Hoan_tien_KT.html"),Map.entry("thanh-toan","Thanh_toan_VietQR_KT.html"),Map.entry("bao-cao","Bao_cao.html"),
  Map.entry("quan-tri","Man_hinh_chinh.html"),Map.entry("cau-hinh","Cau_hinh_san.html"),Map.entry("nhan-su-phan-quyen","Man_hinh_chinh_TK&PQ_HT.html"),Map.entry("doanh-thu","Doanh_thu.html"),Map.entry("sao-luu","Sao_luu.html"));
 public static boolean isPage(String path){return PAGES.containsKey(path.startsWith("/")?path.substring(1):path);}
 public static String home(String role){return switch(role){case "VT01"->"khach-hang";case "VT02"->"nhan-vien";case "VT03"->"hoa-don";default->"quan-tri";};}
 public static String[] legacyPaths(){return PAGES.values().stream().distinct().flatMap(f->java.util.stream.Stream.of("/"+f,"/api/"+f)).toArray(String[]::new);}
 @GetMapping({"/phan-hoi","/trang-chu","/dang-nhap","/dang-ky","/khach-hang","/dat-san","/lich-dat-cua-toi","/dieu-phoi-san","/lich-su-dat-san","/khuyen-mai","/tai-khoan","/nhan-vien","/lich-san","/dat-san-tai-quay","/quan-ly-san","/hoa-don","/hoan-tien","/thanh-toan","/bao-cao","/quan-tri","/cau-hinh","/nhan-su-phan-quyen","/doanh-thu","/sao-luu"})
 @ResponseBody
 public ResponseEntity<Resource> page(HttpServletRequest request){String name=PAGES.get(request.getServletPath().substring(1));return ResponseEntity.ok().header(HttpHeaders.SET_COOKIE,ResponseCookie.from("JSESSIONID","").path("/api").maxAge(0).httpOnly(true).sameSite("Lax").build().toString()).contentType(MediaType.TEXT_HTML).cacheControl(CacheControl.noStore()).body(new ClassPathResource("static/"+name));}
 @GetMapping({"/{file:.+\\.html}","/api/{file:.+\\.html}"})
 public void legacy(@PathVariable String file,HttpServletRequest request,HttpServletResponse response)throws IOException{
  String page=PAGES.entrySet().stream().filter(e->e.getValue().equals(file)).map(Map.Entry::getKey).sorted().findFirst().orElse(null);
  if(page==null){response.sendError(404);return;}
  if(file.equals("Quan_ly_lich_dat_san.html")&&request.getUserPrincipal() instanceof org.springframework.security.core.Authentication auth&&auth.getPrincipal() instanceof AccountPrincipal actor&&"VT01".equals(actor.roleId()))page="lich-dat-cua-toi";
  String query=request.getQueryString();response.sendRedirect(request.getContextPath()+"/"+page+(query==null?"":"?"+query));
 }
}
