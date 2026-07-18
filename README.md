# Design and Verification of Synthesizable AMBA AHB to APB Bridge

An industrial-grade hardware bus-bridge architecture developed during the **Maven Silicon Advanced VLSI Design Internship (DI-39)**. Implemented in synthesizable Verilog HDL, this subsystem serves as a dedicated communication gateway between a high-frequency, pipelined **AMBA AHB backbone bus** (interconnecting high-performance processors and DMA controllers) and a low-frequency, non-pipelined **AMBA APB peripheral bus** (driving low-bandwidth device blocks like timers, keypads, and UARTs).

The system architecture prevents data loss across clock domains by managing transaction-level protocols, buffering address/control lines, and injecting automatic wait-states to throttle the pipelined AHB master during slow peripheral accesses.

---

## ⚡ Submodule Hierarchy & Architectural Engineering

The system functions simultaneously as an AHB Slave and an APB Master, splitting processing logic across three distinct hardware blocks:

### 1. AHB Slave Interface Block
*   **Pipeline Data Channels:** Latches incoming addresses, controls (`HWRITE`, `HTRANS`), and write data buses (`HWDATA`).
*   **Procedural Pipelining:** Uses sequential blocks with non-blocking assignments (`<=`) to pipeline and align control paths by exactly **two clock cycles** before exposing them to the APB domain.
*   **Combinational Decoder Matrix:** Evaluates active `HADDR` registers against a combinational address map to generate localized peripheral select vectors (`tempselx[2:0]`):
    *   `32'h8000_0000` to `32'h8400_0000` $\rightarrow$ `tempselx = 3'b001`
    *   `32'h8400_0000` to `32'h8800_0000` $\rightarrow$ `tempselx = 3'b010`
    *   `32'h8800_0000` to `32'h8C00_0000` $\rightarrow$ `tempselx = 3'b100`

### 2. APB Controller State Machine
*   **Independent FSM Processing:** Operates independently of the underlying memory map using an algorithmic state-table to steer peripheral transfers.
*   **8-State Protocol Tracking:** Features fully mapped state variables to maintain AMBA compliance across asynchronous parameters:
    *   `st_idle` ($3'b000$): Standby state evaluating the pipeline `Valid` condition.
    *   `st_read` ($3'b001$) / `st_readenable` ($3'b010$): Two-cycle peripheral read handling where `penable` asserts to sample `PRDATA` safely.
    *   `st_write` ($3'b011$) / `st_writeenable` ($3'b100$): Standard two-cycle peripheral write sequences.
    *   `st_writepending` ($3'b101$) / `st_writeenablepending` ($3'b110$) / `st_writewait` ($3'b111$): Multi-cycle handshake holds that inject wait-states to throttle back-to-back master streams.

### 3. Top-Level Bridge System Wrapper (`AHBAPB_bridge`)
*   Integrates both submodules and routes wire paths connecting the slave interface boundaries directly into the APB controller register queues.
*   **Directional Isolation:** Implements isolated directional pathways for the peripheral data lines—separating read paths (`PRDATA`) and write paths (`PWDATA`)—eliminating turn-around delays and preventing physical bus clashes.

---

## 🔬 Functional Verification & Waveform Profiles

Functional validation and protocol timing checks were performed using **ModelSim (Intel FPGA Starter Edition)**. The exhaustive simulation test suite handles advanced AMBA corner cases:

*   **Master Single Read/Write:** Verifies fixed-width, single-word transactions. Validates correct `PENABLE` tracking relative to `HCLK` rising edges during standalone cycles.
*   **Master Burst Read/Write:** Forces the bridge to process uninterrupted stream sequences by tracking incremental address loops (`haddr + 1`) and evaluating `$random` data pattern lines, proving the robustness of the wait-state insertion loop under high throughput load.

---
