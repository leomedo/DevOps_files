# ========================
# 🏗️ Builder Stage
# ========================
FROM python:3.10-slim as builder

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/frappe/.local/bin:$PATH"

# تثبيت المتطلبات الأساسية
RUN apt-get update && apt-get install -y \
    git \
    curl \
    nodejs \
    npm \
    redis-server \
    mariadb-client \
    wkhtmltopdf \
    libffi-dev \
    build-essential \
    libssl-dev \
    python3-dev \
    && apt-get clean

# إضافة مستخدم frappe
RUN useradd -m -s /bin/bash frappe
USER frappe
WORKDIR /home/frappe

# تثبيت bench
RUN pip install --user frappe-bench

# تهيئة bench مع الفرع المطلوب من frappe
RUN bench init frappe-bench --frappe-branch version-15

WORKDIR /home/frappe/frappe-bench

# تحميل تطبيق ERPNext
RUN bench get-app --branch version-15 erpnext https://github.com/frappe/erpnext

# ========================
# 🚀 Final Image
# ========================
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/frappe/.local/bin:$PATH"

# تثبيت الحزم اللازمة للتشغيل
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm \
    cron \
    nginx \
    supervisor \
    wkhtmltopdf \
    curl \
    git \
    libssl-dev \
    libffi-dev \
    libmariadb-dev \
    gnupg \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y yarn \
    && apt-get clean
RUN npm install -g yarn
# إضافة مستخدم frappe
RUN useradd -m -s /bin/bash frappe

# نسخ ملفات bench من مرحلة البناء
COPY --from=builder /home/frappe /home/frappe

# تعيين الصلاحيات
RUN chown -R frappe:frappe /home/frappe

USER frappe
WORKDIR /home/frappe/frappe-bench

# تثبيت متطلبات Python
RUN pip3 install -r requirements.txt

# بناء الملفات الأمامية (frontend)
RUN bench build --production

# فتح البورتات اللازمة
EXPOSE 8000 9000

# الأمر الافتراضي
CMD ["bench", "start"]
