# Design and Verification of Synthesizable AMBA AHB to APB Bridge

An industrial-grade hardware bus-bridge architecture implemented in synthesizable Verilog HDL, this subsystem serves as a dedicated communication gateway between a high-frequency, pipelined **AMBA AHB backbone bus** (interconnecting high-performance processors and DMA controllers) and a low-frequency, non-pipelined **AMBA APB peripheral bus** (driving low-bandwidth device blocks like timers, keypads, and UARTs).

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

Functional validation and protocol timing checks were performed using **ModelSim**. The exhaustive simulation test suite handles advanced AMBA corner cases:

*   **Master Single Read/Write:** Verifies fixed-width, single-word transactions. Validates correct `PENABLE` tracking relative to `HCLK` rising edges during standalone cycles.
*   **Master Burst Read/Write:** Forces the bridge to process uninterrupted stream sequences by tracking incremental address loops (`haddr + 1`) and evaluating `$random` data pattern lines, proving the robustness of the wait-state insertion loop under high throughput load.

---

## 🛠️ Toolchain Infrastructure & Synthesis Environment

To meet strict commercial hardware specifications and ensure protocol validation, the design was processed through an industry-standard synthesis and verification flow:

*   **RTL Design & Simulation Testbench:** Architected, debugged, and behaviorally simulated using **ModelSim**. The verification environment features modular stimulus blocks to assert single and multi-word burst transaction tasks, check protocol-level edge alignments, and track active state variables during data transfer steps.
*   **Logic Synthesis & Gate-Level Netlist:** Compiled, optimized, and structurally synthesized using **Intel Quartus Prime System Edition**. The toolchain maps the synchronous Verilog descriptions into a highly optimized technology mapping network, producing a complete **Gate-Level Netlist** without synthesis latch inferences.
*   **Timing & Pipelining Analysis:** Functional timing checks verify the bridge accurately routes multi-word burst data packets over the bus matrix lines, validating correct clock tree handshakes with zero data truncation under high throughput loads.

---

## 📂 Repository Layout & Project Artifacts

All structural design modules, behavioral verification models, block schematics, and simulation timing waveform captures are hosted directly within the flat root directory for direct evaluation:

### 💻 Hardware Design & Simulation Codebases
*   `AHBAPB_bridge` — Top-level system structural design wrapper connecting the bus data lines.
*   `AHB_slave_interface.v` — Synthesizable Verilog module containing protocol address decoding logic and data pipeline registers.
*   `APB_controller` — Synthesizable Verilog implementation of the 8-state APB bus protocol controller.
*   `AHB_master` — Behavioral master stimulus verification model containing standalone and burst transaction tasks.

### 🗺️ System Blueprints & State Machinery Layouts
*   `AHB to APB bridge block diagram.jpg` — Hardware architecture block blueprint detailing system port interfaces.
*   `State table of APB Controller.jpg` — Algorithmic FSM state machine flowchart illustrating state transition criteria.

### 🖥️ Technology Netlist RTL Schematics
*   `RTL Schematic of AHB Slave Interface.jpg` — Synthesized technology netlist gate capture outlining the combinational address logic.
*   `RTL schematic of APB Controller.jpg` — Synthesized gate-level logic schematics tracking internal temp registers.
*   `Bridge Circuit RTL Schematic.jpg` — Complete top-level technology schematic highlighting structural module wiring.

### 📊 ModelSim Timing Simulation Waveforms
*   `MASTER_SINGLE_READ.jpg` — Functional wave logs validating single-word standalone read transactions.
*   `MASTER_SINGLE_WRITE.jpg` — Functional wave logs validating single-word standalone write transactions.
*   `MASTER_BURST_READ.jpg` — Functional wave logs validating consecutive multi-word burst read data streams.
*   `MASTER_BURST_WRITE.jpg` — Functional wave logs validating consecutive multi-word burst write data streams.
*   `README.md` — Main technical architectural specification and portfolio landing page.
