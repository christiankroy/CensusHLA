# Use the rocker/verse image as the base image
FROM rocker/verse:latest

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install additional system dependencies including libudunits2-dev
RUN apt-get update && apt-get install -y --no-install-recommends \
    libudunits2-dev \
    libgdal-dev \
    libproj-dev \
    libgeos-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify the shared library is installed
RUN ldconfig -p | grep libudunits2.so.0

# Set working directory
WORKDIR /home/rstudio

# Expose RStudio Server port
EXPOSE 8787

# Set default command (optional)
CMD ["/init"]