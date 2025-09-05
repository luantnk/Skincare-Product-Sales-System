"use client";
import React, { useEffect, useState } from "react";
import Nav from "./Nav";
import Link from "next/link";
import { MdLogout } from "react-icons/md";
import useAuthStore from "@/context/authStore";
import useQueryStore from "@/context/queryStore";
import request from "@/utils/axios";

export default function Header2({
  textClass,
  bgColor = "",
  uppercase = false,
  isArrow = true,
  Linkfs = "",
}) {
  const { isLoggedIn, setLoggedOut, Role } = useAuthStore();
  const { switcher, revalidate } = useQueryStore();
  const [cartProducts, setCartProducts] = useState([]);
  const [isStaff, setIsStaff] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [isMobile, setIsMobile] = useState(false);

  // Kiểm tra xem người dùng có phải là staff hay không sử dụng localStorage
  useEffect(() => {
    setMounted(true);
    if (typeof window !== 'undefined') {
      try {
        const userRole = localStorage.getItem("userRole");
        console.log("Header2 - User role from localStorage:", userRole);
        setIsStaff(userRole === 'Staff');

        // Check if mobile
        const checkIfMobile = () => {
          setIsMobile(window.innerWidth <= 768);
        };

        // Initial check
        checkIfMobile();

        // Add event listener
        window.addEventListener('resize', checkIfMobile);

        // Cleanup
        return () => window.removeEventListener('resize', checkIfMobile);
      } catch (error) {
        console.error("Error reading role from localStorage:", error);
      }
    }
  }, []);

  useEffect(() => {
    if (!isLoggedIn || isStaff) return;

    //> fetch data from server
    request
      .get("/cart-items/user/cart")
      .then((res) => {
        console.log("cart", res?.data?.data?.items);
        setCartProducts(res?.data?.data?.items);
      })
      .catch((e) => setCartProducts([]));
  }, [switcher, isLoggedIn, isStaff]);

  // Nếu chưa mount hoặc người dùng là staff, không hiển thị header
  if (!mounted || isStaff) {
    return null;
  }

  return (
    <header
      id="header"
      className={`header-default ${uppercase ? "header-uppercase" : ""}`}
    >
      <div className="lg-px_40 px_15">
        <div className="row align-items-center wrapper-header" style={{ marginBottom: 0 }}>
          <div className="col-3 col-md-4 tf-lg-hidden">
            <a
              href="#mobileMenu"
              data-bs-toggle="offcanvas"
              aria-controls="offcanvasLeft"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width={24}
                height={16}
                viewBox="0 0 24 16"
                fill="none"
              >
                <path
                  d="M2.00056 2.28571H16.8577C17.1608 2.28571 17.4515 2.16531 17.6658 1.95098C17.8802 1.73665 18.0006 1.44596 18.0006 1.14286C18.0006 0.839753 17.8802 0.549063 17.6658 0.334735C17.4515 0.120408 17.1608 0 16.8577 0H2.00056C1.69745 0 1.40676 0.120408 1.19244 0.334735C0.978109 0.549063 0.857702 0.839753 0.857702 1.14286C0.857702 1.44596 0.978109 1.73665 1.19244 1.95098C1.40676 2.16531 1.69745 2.28571 2.00056 2.28571ZM0.857702 8C0.857702 7.6969 0.978109 7.40621 1.19244 7.19188C1.40676 6.97755 1.69745 6.85714 2.00056 6.85714H22.572C22.8751 6.85714 23.1658 6.97755 23.3801 7.19188C23.5944 7.40621 23.7148 7.6969 23.7148 8C23.7148 8.30311 23.5944 8.59379 23.3801 8.80812C23.1658 9.02245 22.8751 9.14286 22.572 9.14286H2.00056C1.69745 9.14286 1.40676 9.02245 1.19244 8.80812C0.978109 8.59379 0.857702 8.30311 0.857702 8ZM0.857702 14.8571C0.857702 14.554 0.978109 14.2633 1.19244 14.049C1.40676 13.8347 1.69745 13.7143 2.00056 13.7143H12.2863C12.5894 13.7143 12.8801 13.8347 13.0944 14.049C13.3087 14.2633 13.4291 14.554 13.4291 14.8571C13.4291 15.1602 13.3087 15.4509 13.0944 15.6653C12.8801 15.8796 12.5894 16 12.2863 16H2.00056C1.69745 16 1.40676 15.8796 1.19244 15.6653C0.978109 15.4509 0.857702 15.1602 0.857702 14.8571Z"
                  fill="currentColor"
                />
              </svg>
            </a>
          </div>
          <div className="col-6 col-md-4 col-xl-3">
            <Link href={`/`} className="d-flex align-items-center gap-2">
              <img
                alt="image"
                src="/images/logo/logo-icon.png"
                width={isMobile ? "30" : "40"}
                height={isMobile ? "16" : "21"}
                style={{
                  objectFit: "contain",
                }}
              />
              <div
                className="font-sora"
                style={{
                  paddingTop: isMobile ? "5px" : "10px",
                  color: "#0077ffb2",
                  fontSize: isMobile ? "22px" : "30px",
                  fontWeight: "600",
                }}
              >
                Skincede
              </div>
              {/* <Image
                alt="logo"
                className="logo"
                src="/images/logo/logo.png"
                width="136"
                height="21"
              /> */}
            </Link>
          </div>
          <div className="col-xl-6 tf-md-hidden">
            <nav className="text-center box-navigation">
              <ul className="d-flex align-items-center justify-content-center box-nav-ul gap-30">
                {isStaff ? (
                  // Staff Menu
                  <>
                    <li className="menu-item">
                      <Link href="/staff-chat" className={`item-link ${Linkfs}`}>
                        Chăm sóc khách hàng
                      </Link>
                    </li>
                    <li className="menu-item">
                      <Link href="/blog-management" className={`item-link ${Linkfs}`}>
                        Quản lý bài viết
                      </Link>
                    </li>
                  </>
                ) : (
                  // Regular Nav menu
                  <Nav isArrow={isArrow} Linkfs={Linkfs} />
                )}
              </ul>
            </nav>
          </div>
          <div className="col-3 col-md-4 col-xl-3">
            <ul className="d-flex nav-icon align-items-center justify-content-end gap-20">
              {/* <li className="nav-search">
                <a
                  href="#canvasSearch"
                  data-bs-toggle="offcanvas"
                  aria-controls="offcanvasLeft"
                  className="nav-icon-item"
                >
                  <i className="icon icon-search" />
                </a>
              </li> */}
              <li className="nav-account" id="nav-account">
                <a
                  href={isLoggedIn ? "/my-account" : "#login"}
                  data-bs-toggle={isLoggedIn ? "" : "modal"}
                  data-bs-target={isLoggedIn ? "" : "#login"}
                  className="nav-icon-item"
                >
                  <i className="icon icon-account" />
                </a>
              </li>
              {!isStaff && (
                <li className="nav-cart">
                  <a
                    href="#shoppingCart"
                    data-bs-toggle="modal"
                    className="nav-icon-item"
                    onClick={() => revalidate()}
                  >
                    <i className="icon icon-bag" />
                    <span className={`count-box ${bgColor} ${textClass}`}>
                      {cartProducts.length}
                    </span>
                  </a>
                </li>
              )}
              {isLoggedIn && (
                <li className="nav-cart">
                  <a
                    className="nav-icon-item"
                    onClick={() => {
                      setLoggedOut();
                      localStorage.removeItem("accessToken");
                      localStorage.removeItem("refreshToken");
                      localStorage.removeItem("userRole");
                      window.location.href = '/';
                    }}
                  >
                    <MdLogout size={isMobile ? 16 : 20} />
                  </a>
                </li>
              )}
            </ul>
          </div>
        </div>
      </div>
    </header>
  );
}