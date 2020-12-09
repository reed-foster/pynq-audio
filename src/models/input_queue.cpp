#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

class InputQueue {
private:
    uint32_t* buffer;
    uint16_t read_addr;
    uint16_t read_stop;
    uint16_t write_addr;
    uint16_t write_stop;
    bool write_ok;
    bool read_ok;
    bool init;

public:
    InputQueue() {
        buffer = new uint32_t[1024];
        read_addr = 0;
        read_stop = 0;
        write_addr = 0;
        write_stop = 0;
        write_ok = true;
        read_ok = false;
        init = true;
    }

    virtual ~InputQueue() {
        delete buffer;
    }

    uint16_t get_write_addr() {
        return write_addr;
    }

    uint16_t get_read_addr() {
        return read_addr;
    }

    uint16_t get_write_stop() {
        return write_stop;
    }

    uint16_t get_read_stop() {
        return read_stop;
    }

    uint16_t increment_10b_val(uint16_t val, uint16_t inc) {
        return (val + inc) & 1023;
    }

    bool write(uint32_t value) {
        if (write_ok) {
            buffer[write_addr] = value;
            write_addr = increment_10b_val(write_addr, 1);
            if (write_addr == write_stop) {
                write_stop = increment_10b_val(write_addr, 512);
                write_ok = false;
                read_ok = true;
            }
            return true;
        }
        return false;
    }

    bool read(uint32_t &value) {
        if (read_ok) {
            value = buffer[read_addr];
            read_addr = increment_10b_val(read_addr, 1);
            if (read_addr == read_stop) {
                read_stop = increment_10b_val(read_stop, 512);
                read_addr = read_stop;
                //printf("\n\nread overflowed, setting read_stop to %d\n\n", read_stop);
                write_ok = true;
                read_ok = false;
            } 
            if (read_addr == write_addr) {
                read_ok = false;
                write_ok = true;
            }
            return true;
        }
        return false;
    }

    void dump_buffer() {
        int w = 16;
        int h = 64;
        for (int i = 0; i < h; i++) {
            for (int j = 0; j < w; j++) {
                printf("0x%06x", buffer[i*w + j]);
                if (j == w-1) printf("\n");
                else printf(", ");
            }
        }
    }
};

int main(void) {
    InputQueue q;
    uint32_t read_reg;

    srand(69);
    bool success;
    int count;
    for (int i = 0; i < 10; i++) {
        count = 0;
        while (true) {
            uint32_t val = rand() % (1 << 24);
            uint16_t addr = q.get_write_addr();
            success = q.write(val);
            if (!success) {
                printf("\nwrote %d values before failure\n", count);
                printf("read_addr = %d, read_stop = %d\n", q.get_read_addr(), q.get_read_stop());
                printf("write_addr = %d, write_stop = %d\n", q.get_write_addr(), q.get_write_stop());
                break;
            }
            count++;
        }
        count = 0;
        while (true) {
            uint16_t addr = q.get_read_addr();
            success = q.read(read_reg);
            if (!success) {
                printf("\nread %d values before failure\n", count);
                printf("read_addr = %d, read_stop = %d\n", q.get_read_addr(), q.get_read_stop());
                printf("write_addr = %d, write_stop = %d\n", q.get_write_addr(), q.get_write_stop());
                break;
            }
            count++;
        }
    }
    return 0;
}

