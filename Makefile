# ============================================================================
# Thunder OS - Bare Metal AArch64 Operating System
# ============================================================================
#
# Development environment:
#   Windows
#   MSYS2 UCRT64
#   VS Code
#
# Targets:
#   QEMU ARM64 virt machine
#   Raspberry Pi 4
#
# ============================================================================

PROJECT := thunder-os
VERSION := 0.1.0

# ============================================================================
# Toolchain
# ============================================================================

# MSYS2 path to the ARM GNU bare-metal toolchain.
#
# Windows:
#   C:\arm-gnu\bin\aarch64-none-elf-gcc.exe
#
# MSYS2:
#   /c/arm-gnu/bin/aarch64-none-elf-gcc.exe
#
CROSS ?= /c/arm-gnu/bin/aarch64-none-elf-

CC      := $(CROSS)gcc
AS      := $(CROSS)gcc
LD      := $(CROSS)ld
AR      := $(CROSS)ar
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
READELF := $(CROSS)readelf
SIZE    := $(CROSS)size
NM      := $(CROSS)nm
STRIP   := $(CROSS)strip
GDB     := $(CROSS)gdb

# ============================================================================
# Host tools
# ============================================================================

QEMU ?= qemu-system-aarch64

BOARD ?= qemu

ifeq ($(BOARD),qemu)
    BOARD_DEFINE := -DTHUNDER_QEMU
    BOARD_INC := -I$(INC_DIR)/board/qemu
else ifeq ($(BOARD),rpi4)
    BOARD_DEFINE := -DTHUNDER_RPI4
    BOARD_INC := -I$(INC_DIR)/board/rpi4
else
    $(error Unknown BOARD '$(BOARD)'. Use BOARD=qemu or BOARD=rpi4)
endif

# ============================================================================
# Directories
# ============================================================================

SRC_DIR   := src
INC_DIR   := include
BUILD_DIR := build
BIN_DIR   := bin

OBJ_DIR := $(BUILD_DIR)/obj

# ============================================================================
# Output
# ============================================================================

KERNEL_ELF  := $(BIN_DIR)/kernel.elf
KERNEL_BIN  := $(BIN_DIR)/kernel.bin
KERNEL_IMG  := $(BIN_DIR)/kernel8.img
KERNEL_MAP  := $(BIN_DIR)/kernel.map
KERNEL_DUMP := $(BIN_DIR)/kernel.disasm

# ============================================================================
# Architecture
# ============================================================================

ARCH_FLAGS := \
	-march=armv8-a \
	-mcpu=cortex-a72

# ============================================================================
# Compiler flags
# ============================================================================

COMMON_FLAGS := \
	-ffreestanding \
	-fno-builtin \
	-fno-stack-protector \
	-fno-pic \
	-fno-pie \
	-fno-asynchronous-unwind-tables \
	-fno-unwind-tables \
	-fdata-sections \
	-ffunction-sections

WARNING_FLAGS := \
	-Wall \
	-Wextra \
	-Wpedantic \
	-Wshadow \
	-Wconversion \
	-Wsign-conversion \
	-Wundef \
	-Werror=return-type

C_FLAGS := \
	-std=c11 \
	$(ARCH_FLAGS) \
	$(COMMON_FLAGS) \
	$(WARNING_FLAGS) \
	-O2 \
	-g3 \
	-I$(INC_DIR) \
	$(BOARD_INC) \
	$(BOARD_DEFINE) \
	-MMD \
	-MP

ASM_FLAGS := \
	$(ARCH_FLAGS) \
	$(COMMON_FLAGS) \
	-g3 \
	-I$(INC_DIR)

# ============================================================================
# Linker
# ============================================================================

# QEMU virt loads the kernel at a different address from a real Pi 4.
#
# For now, we're developing against QEMU.
LDSCRIPT := linker-qemu.ld

LD_FLAGS := \
	-T $(LDSCRIPT) \
	-z max-page-size=4096 \
	-nostdlib \
	--gc-sections \
	-Map=$(KERNEL_MAP)

# ============================================================================
# Source discovery
# ============================================================================

# Recursively find all C and assembly files under src/.
C_SOURCES := $(shell find "$(SRC_DIR)" -type f -name '*.c')
S_SOURCES := $(shell find "$(SRC_DIR)" -type f -name '*.S')

# Convert:
#
#   src/kernel/kernel.c
#
# into:
#
#   build/obj/kernel/kernel.o
#
C_OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(C_SOURCES))
S_OBJECTS := $(patsubst $(SRC_DIR)/%.S,$(OBJ_DIR)/%.o,$(S_SOURCES))

OBJECTS := $(C_OBJECTS) $(S_OBJECTS)

# GCC generates dependency files next to the object files.
DEPFILES := $(OBJECTS:.o=.d)

# ============================================================================
# QEMU
# ============================================================================

QEMU_MACHINE := virt
QEMU_CPU     := cortex-a72
QEMU_MEMORY  := 1024

QEMU_FLAGS := \
	-machine $(QEMU_MACHINE) \
	-cpu $(QEMU_CPU) \
	-m $(QEMU_MEMORY)M \
	-nographic \
	-serial mon:stdio \
	-no-reboot \
	-no-shutdown

QEMU_DEBUG_FLAGS := \
	-machine $(QEMU_MACHINE) \
	-cpu $(QEMU_CPU) \
	-m $(QEMU_MEMORY)M \
	-nographic \
	-serial mon:stdio \
	-S \
	-gdb tcp::1234 \
	-no-reboot \
	-no-shutdown

# ============================================================================
# Default
# ============================================================================

.DEFAULT_GOAL := all

# ============================================================================
# Phony targets
# ============================================================================

.PHONY: \
	all \
	build \
	kernel \
	run \
	debug \
	gdb \
	clean \
	rebuild \
	check \
	check-tools \
	setup \
	info \
	size \
	disasm \
	symbols \
	sections \
	headers \
	image \
	flash \
	format \
	test \
	help \
	version

# ============================================================================
# Build
# ============================================================================

all: build

build: kernel

kernel: $(KERNEL_ELF) $(KERNEL_BIN) $(KERNEL_IMG)

# ============================================================================
# C compilation
# ============================================================================

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@echo "[CC]   $<"
	@mkdir -p "$(dir $@)"
	@$(CC) $(C_FLAGS) -c "$<" -o "$@"

# ============================================================================
# Assembly compilation
# ============================================================================

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S
	@echo "[AS]   $<"
	@mkdir -p "$(dir $@)"
	@$(AS) $(ASM_FLAGS) -c "$<" -o "$@"

# ============================================================================
# Linking
# ============================================================================

$(KERNEL_ELF): $(OBJECTS) $(LDSCRIPT)
	@echo
	@echo "[LD]   $@"
	@mkdir -p "$(BIN_DIR)"
	@$(LD) $(LD_FLAGS) $(OBJECTS) -o "$@"
	@echo "[OK]   Kernel linked"

# ============================================================================
# ELF -> binary
# ============================================================================

$(KERNEL_BIN): $(KERNEL_ELF)
	@echo "[BIN]  $@"
	@$(OBJCOPY) -O binary "$<" "$@"

# ============================================================================
# kernel8.img
# ============================================================================

$(KERNEL_IMG): $(KERNEL_ELF)
	@echo "[IMG]  $@"
	@$(OBJCOPY) -O binary "$<" "$@"

# ============================================================================
# Dependencies
# ============================================================================

-include $(DEPFILES)

# ============================================================================
# QEMU
# ============================================================================

run: kernel
	@echo
	@echo "=============================================="
	@echo " Starting $(PROJECT) $(VERSION)"
	@echo "=============================================="
	@echo
	@$(QEMU) $(QEMU_FLAGS) -kernel "$(KERNEL_ELF)"

# ============================================================================
# Debugging
# ============================================================================

debug: kernel
	@echo
	@echo "=============================================="
	@echo " QEMU waiting for GDB"
	@echo " localhost:1234"
	@echo "=============================================="
	@echo
	@echo "In another terminal run:"
	@echo
	@echo "    make gdb"
	@echo
	@$(QEMU) $(QEMU_DEBUG_FLAGS) -kernel "$(KERNEL_ELF)"

gdb: kernel
	@echo "[GDB] Connecting to QEMU..."
	@$(GDB) "$(KERNEL_ELF)" \
		-ex "set architecture aarch64" \
		-ex "target remote localhost:1234"

# ============================================================================
# Inspection
# ============================================================================

size: kernel
	@echo
	@$(SIZE) "$(KERNEL_ELF)"

disasm: kernel
	@echo "[OBJDUMP] Generating disassembly..."
	@$(OBJDUMP) -d -S "$(KERNEL_ELF)" > "$(KERNEL_DUMP)"
	@echo "[OK] $(KERNEL_DUMP)"

symbols: kernel
	@$(NM) -n "$(KERNEL_ELF)"

sections: kernel
	@$(READELF) -S "$(KERNEL_ELF)"

headers: kernel
	@$(READELF) -h "$(KERNEL_ELF)"

# ============================================================================
# Information
# ============================================================================

info:
	@echo
	@echo "=============================================="
	@echo " $(PROJECT) build configuration"
	@echo "=============================================="
	@echo
	@echo "Project:       $(PROJECT)"
	@echo "Version:       $(VERSION)"
	@echo
	@echo "Toolchain:     $(CROSS)"
	@echo "Compiler:      $(CC)"
	@echo "Linker:        $(LD)"
	@echo "Objcopy:       $(OBJCOPY)"
	@echo "Objdump:       $(OBJDUMP)"
	@echo "GDB:           $(GDB)"
	@echo "QEMU:          $(QEMU)"
	@echo
	@echo "Architecture:  AArch64"
	@echo "CPU:            Cortex-A72"
	@echo "Machine:       $(QEMU_MACHINE)"
	@echo
	@echo "Linker script:  $(LDSCRIPT)"
	@echo
	@echo "C sources:     $(words $(C_SOURCES))"
	@echo "ASM sources:   $(words $(S_SOURCES))"
	@echo "Objects:       $(words $(OBJECTS))"
	@echo

version:
	@echo "$(PROJECT) $(VERSION)"

# ============================================================================
# Dependency checks
# ============================================================================

check-tools:
	@echo
	@echo "Checking development tools..."
	@echo

	@command -v "$(CC)" >/dev/null 2>&1 \
		&& echo "[OK]   $(CC)" \
		|| echo "[MISS] $(CC)"

	@command -v "$(LD)" >/dev/null 2>&1 \
		&& echo "[OK]   $(LD)" \
		|| echo "[MISS] $(LD)"

	@command -v "$(OBJCOPY)" >/dev/null 2>&1 \
		&& echo "[OK]   $(OBJCOPY)" \
		|| echo "[MISS] $(OBJCOPY)"

	@command -v "$(OBJDUMP)" >/dev/null 2>&1 \
		&& echo "[OK]   $(OBJDUMP)" \
		|| echo "[MISS] $(OBJDUMP)"

	@command -v "$(SIZE)" >/dev/null 2>&1 \
		&& echo "[OK]   $(SIZE)" \
		|| echo "[MISS] $(SIZE)"

	@command -v "$(NM)" >/dev/null 2>&1 \
		&& echo "[OK]   $(NM)" \
		|| echo "[MISS] $(NM)"

	@command -v "$(GDB)" >/dev/null 2>&1 \
		&& echo "[OK]   $(GDB)" \
		|| echo "[MISS] $(GDB)"

	@command -v "$(QEMU)" >/dev/null 2>&1 \
		&& echo "[OK]   $(QEMU)" \
		|| echo "[MISS] $(QEMU)"

	@echo

check: check-tools
	@echo "Checking source tree..."
	@echo

	@test -f "$(LDSCRIPT)" \
		&& echo "[OK]   $(LDSCRIPT)" \
		|| echo "[MISS] $(LDSCRIPT)"

	@test -d "$(SRC_DIR)" \
		&& echo "[OK]   $(SRC_DIR)/" \
		|| echo "[MISS] $(SRC_DIR)/"

	@test -d "$(INC_DIR)" \
		&& echo "[OK]   $(INC_DIR)/" \
		|| echo "[MISS] $(INC_DIR)/"

	@echo

# ============================================================================
# Setup
# ============================================================================

setup:
	@echo
	@echo "=============================================="
	@echo " Thunder development environment"
	@echo "=============================================="
	@echo

	@command -v "$(CC)" >/dev/null 2>&1 \
		|| (echo "ERROR: AArch64 GCC not found."; \
		    echo "Expected: /c/arm-gnu/bin/aarch64-none-elf-gcc"; \
		    exit 1)

	@command -v "$(QEMU)" >/dev/null 2>&1 \
		|| (echo "ERROR: QEMU not found."; \
		    echo "Install qemu-system-aarch64."; \
		    exit 1)

	@command -v "$(GDB)" >/dev/null 2>&1 \
		|| (echo "ERROR: AArch64 GDB not found."; \
		    exit 1)

	@echo
	@echo "[OK] Development environment is ready."
	@echo

# ============================================================================
# Cleaning
# ============================================================================

clean:
	@echo "[CLEAN] Removing build output..."
	@rm -rf "$(BUILD_DIR)"
	@rm -rf "$(BIN_DIR)"

rebuild: clean build

# ============================================================================
# Raspberry Pi image preparation
# ============================================================================

image: kernel
	@echo
	@echo "[IMAGE] Raspberry Pi kernel:"
	@echo "        $(KERNEL_IMG)"
	@echo
	@echo "A complete Pi boot image will be implemented"
	@echo "when the Raspberry Pi board target is added."

flash:
	@echo
	@echo "Flash support is intentionally disabled for now."
	@echo "We will add a safe Raspberry Pi SD-card target later."
	@echo

# ============================================================================
# Formatting
# ============================================================================

format:
	@command -v clang-format >/dev/null 2>&1 \
		&& find "$(SRC_DIR)" "$(INC_DIR)" \
			-type f \( -name '*.c' -o -name '*.h' \) \
			-exec clang-format -i {} \; \
		|| echo "[SKIP] clang-format not installed."

format-check:
	@command -v clang-format >/dev/null 2>&1 \
		&& find "$(SRC_DIR)" "$(INC_DIR)" \
			-type f \( -name '*.c' -o -name '*.h' \) \
			-exec clang-format --dry-run --Werror {} \; \
		|| echo "[SKIP] clang-format not installed."

# ============================================================================
# Tests
# ============================================================================

test:
	@echo "No tests configured yet."

# ============================================================================
# Help
# ============================================================================

help:
	@echo
	@echo "=============================================="
	@echo " Thunder OS Build System"
	@echo "=============================================="
	@echo
	@echo "Build:"
	@echo "  make                 Build the kernel"
	@echo "  make build           Build the kernel"
	@echo "  make kernel          Build all kernel outputs"
	@echo "  make rebuild         Clean and rebuild"
	@echo "  make clean           Remove generated files"
	@echo
	@echo "Run:"
	@echo "  make run             Boot in QEMU"
	@echo
	@echo "Debug:"
	@echo "  make debug           Start QEMU waiting for GDB"
	@echo "  make gdb             Connect GDB"
	@echo
	@echo "Inspection:"
	@echo "  make size            Show kernel size"
	@echo "  make disasm          Generate disassembly"
	@echo "  make symbols         List symbols"
	@echo "  make sections        Show ELF sections"
	@echo "  make headers         Show ELF headers"
	@echo "  make info            Show configuration"
	@echo
	@echo "Development:"
	@echo "  make setup           Check dependencies"
	@echo "  make check           Check tools and source"
	@echo "  make format          Format source"
	@echo "  make format-check    Check formatting"
	@echo
	@echo "Raspberry Pi:"
	@echo "  make image           Prepare Pi kernel"
	@echo "  make flash           Flash Pi"
	@echo
	@echo "=============================================="
	@echo