#!/usr/bin/env bash
set -euo pipefail

echo ">>> Rewriting Thymeleaf templates (safe header/footer include)"

TPL_DIR="src/main/resources/templates"
mkdir -p "$TPL_DIR"

# layout.html (เฉพาะ header/footer fragments)
cat > "$TPL_DIR/layout.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title th:text="${title} ?: 'Uni Activities'">Uni Activities</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
<header th:fragment="header" class="topbar">
  <div class="container">
    <a class="brand" th:href="@{/}">Uni Activities</a>
    <nav>
      <span th:if="${isAuthenticated}">
        สวัสดี, <b th:text="${currentUserName}">User</b>
        <a th:if="${isStaff}" th:href="@{/jobs/new}">ลงประกาศงาน</a>
        <a th:if="${isStaff}" th:href="@{/me/posted}">งานที่ฉันสร้าง</a>
        <a th:if="${isStudent}" th:href="@{/me/applications}">การสมัครของฉัน</a>
        <a th:href="@{/logout}">ออกจากระบบ</a>
      </span>
      <span th:if="${!isAuthenticated}">
        <a th:href="@{/login}">เข้าสู่ระบบ</a>
        <a th:href="@{/register}">สมัครสมาชิก</a>
      </span>
    </nav>
  </div>
</header>

<footer th:fragment="footer" class="footer">
  <div class="container">
    <small>Prototype • Spring Boot + Docker • สำหรับใช้งานภายในมหาลัย</small>
  </div>
</footer>
</body>
</html>
HTML

# index.html
cat > "$TPL_DIR/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Uni Activities</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
  <div th:replace="~{layout :: header}"></div>
  <main class="container">
    <h1>ประกาศงาน/กิจกรรมล่าสุด</h1>
    <div class="cards" th:if="${#lists.isEmpty(jobs)}">
      <p>ยังไม่มีประกาศงาน</p>
    </div>
    <div class="cards" th:if="${!#lists.isEmpty(jobs)}">
      <div class="card" th:each="j : ${jobs}">
        <h3><a th:href="@{'/jobs/' + ${j.id}}" th:text="${j.title}">ชื่องาน</a></h3>
        <p th:text="${j.description.length() > 140 ? j.description.substring(0,140) + '...' : j.description}">รายละเอียด</p>
        <p><b>สถานที่:</b> <span th:text="${j.location}">ที่ตั้ง</span></p>
        <p><b>หมวด:</b> <span th:text="${j.category} ?: '-'">หมวด</span></p>
      </div>
    </div>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML

# login.html
cat > "$TPL_DIR/login.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>เข้าสู่ระบบ</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
  <div th:replace="~{layout :: header}"></div>
  <main class="container">
    <h1>เข้าสู่ระบบ</h1>
    <form method="post" th:action="@{/login}">
      <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
      <label>อีเมล <input type="email" name="username" required/></label>
      <label>รหัสผ่าน <input type="password" name="password" required/></label>
      <button type="submit">เข้าสู่ระบบ</button>
    </form>
    <p>ทดสอบ: staff@uni.local / 123456 หรือ student@uni.local / 123456</p>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML

# register.html
cat > "$TPL_DIR/register.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>สมัครสมาชิก</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
  <div th:replace="~{layout :: header}"></div>
  <main class="container">
    <h1>สมัครสมาชิก</h1>
    <p class="error" th:if="${error}" th:text="${error}"></p>
    <form method="post" th:action="@{/register}">
      <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
      <label>อีเมล <input type="email" name="email" required/></label>
      <label>ชื่อ-นามสกุล <input type="text" name="fullName" required/></label>
      <label>รหัสผ่าน <input type="password" name="password" required/></label>
      <label>บทบาท
        <select name="role" id="role-select" onchange="toggleStaffSecret()">
          <option value="STUDENT">นักศึกษา</option>
          <option value="STAFF">อาจารย์/บุคลากร</option>
        </select>
      </label>
      <div id="staff-secret" style="display:none;">
        <label>รหัสยืนยัน STAFF <input type="text" name="staffSecretInput" placeholder="ขอจากฝ่ายกิจการนิสิต"/></label>
      </div>
      <button type="submit">สมัคร</button>
    </form>
    <script>
      function toggleStaffSecret(){
        const role = document.getElementById("role-select").value;
        document.getElementById("staff-secret").style.display = role === "STAFF" ? "block" : "none";
      }
      toggleStaffSecret();
    </script>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML

# job_form.html
cat > "$TPL_DIR/job_form.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>ลงประกาศงาน</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
  <div th:replace="~{layout :: header}"></div>
  <main class="container">
    <h1>ลงประกาศงาน (STAFF)</h1>
    <form method="post" th:action="@{/jobs}">
      <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
      <label>ชื่องาน <input type="text" name="title" required/></label>
      <label>สถานที่ <input type="text" name="location" required/></label>
      <label>หมวดหมู่ <input type="text" name="category" placeholder="เช่น Volunteer, งาน Staff"/></label>
      <label>รายละเอียด
        <textarea name="description" rows="6" required></textarea>
      </label>
      <button type="submit">บันทึกประกาศ</button>
    </form>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML

# job_detail.html
cat > "$TPL_DIR/job_detail.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>รายละเอียดงาน</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
  <div th:replace="~{layout :: header}"></div>
  <main class="container">
    <h1 th:text="${job.title}">งาน</h1>
    <p><b>สถานที่:</b> <span th:text="${job.location}">-</span></p>
    <p><b>หมวด:</b> <span th:text="${job.category} ?: '-'">-</span></p>
    <pre class="desc" th:text="${job.description}">รายละเอียด</pre>

    <div th:if="${isStudent}">
      <h2>สมัครเข้าร่วม</h2>
      <form method="post" th:action="@{'/jobs/' + ${job.id} + '/apply'}">
        <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
        <label>เหตุผล/แรงจูงใจ
          <textarea name="motivation" rows="4" required placeholder="เล่าเหตุผล/ประสบการณ์สั้นๆ"></textarea>
        </label>
        <button type="submit">ส่งใบสมัคร</button>
      </form>
    </div>

    <div th:if="${!isStudent}">
      <p><i>เฉพาะนักศึกษาที่เข้าสู่ระบบในบทบาท STUDENT จึงจะเห็นแบบฟอร์มสมัคร</i></p>
    </div>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML

# my_applications.html
cat > "$TPL_DIR/my_applications.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>การสมัครของฉัน</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
  <div th:replace="~{layout :: header}"></div>
  <main class="container">
    <h1>การสมัครของฉัน</h1>
    <div class="cards" th:if="${#lists.isEmpty(apps)}">
      <p>ยังไม่มีการสมัคร</p>
    </div>
    <div class="cards" th:if="${!#lists.isEmpty(apps)}">
      <div class="card" th:each="a : ${apps}">
        <h3 th:text="${a.job.title}">งาน</h3>
        <p><b>สมัครเมื่อ:</b> <span th:text="${#temporals.format(a.createdAt, 'yyyy-MM-dd HH:mm')}">เวลา</span></p>
        <p><b>เหตุผล:</b></p>
        <pre class="desc" th:text="${a.motivation}">เหตุผล</pre>
      </div>
    </div>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML

# my_posted.html
cat > "$TPL_DIR/my_posted.html" <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns="http://www.w3.org/1999/xhtml" xmlns:th="http://www.thymeleaf.org">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>งานที่ฉันสร้าง</title>
  <link rel="stylesheet" th:href="@{/css/main.css}"/>
</head>
<body>
  <div th:replace="~{layout :: header}"></div>
  <main class="container">
    <h1>งานที่ฉันสร้าง</h1>
    <div class="cards" th:if="${#lists.isEmpty(myjobs)}">
      <p>ยังไม่มีงานที่สร้าง</p>
    </div>
    <div class="cards" th:if="${!#lists.isEmpty(myjobs)}">
      <div class="card" th:each="j : ${myjobs}">
        <h3><a th:href="@{'/jobs/' + ${j.id}}" th:text="${j.title}">ชื่องาน</a></h3>
        <p th:text="${j.description.length() > 140 ? j.description.substring(0,140) + '...' : j.description}">รายละเอียด</p>
        <p><b>สถานที่:</b> <span th:text="${j.location}">ที่ตั้ง</span></p>
        <p><b>หมวด:</b> <span th:text="${j.category} ?: '-'">หมวด</span></p>
      </div>
    </div>
  </main>
  <div th:replace="~{layout :: footer}"></div>
</body>
</html>
HTML

echo ">>> Templates rewritten OK."
