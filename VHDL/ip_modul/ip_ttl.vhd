LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ip_ttl IS
    PORT (
        clock, reset : IN  STD_LOGIC;
        in_data      : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        in_valid     : IN  STD_LOGIC;
        in_sop       : IN  STD_LOGIC;
        in_eop       : IN  STD_LOGIC;
        in_ready     : OUT STD_LOGIC;
        out_data     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        out_valid    : OUT STD_LOGIC;
        out_sop      : OUT STD_LOGIC;
        out_eop      : OUT STD_LOGIC;
        out_ready    : IN  STD_LOGIC;
        drop         : OUT STD_LOGIC
    );
END ip_ttl;

ARCHITECTURE bhv OF ip_ttl IS
    TYPE state_type IS (IDLE, ETHERNET_HEADER, IP_HEADER, PACKET_PASSED, PACKET_DROPPED, SEND_ICMP);
    SIGNAL state : state_type;

    SIGNAL byte_cnt : INTEGER RANGE 0 TO 255 := 0;
    SIGNAL icmp_cnt : INTEGER RANGE 0 TO 255 := 0;
    
    TYPE pkt_buffer_type IS ARRAY (0 TO 63) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL pkt_buffer : pkt_buffer_type := (OTHERS => (OTHERS => '0'));
    
    SIGNAL src_mac_addr : STD_LOGIC_VECTOR(47 DOWNTO 0) := (OTHERS => '0');
    SIGNAL src_ip_addr  : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL drop_reg : STD_LOGIC := '0';

    CONSTANT MODULE_MAC : STD_LOGIC_VECTOR(47 DOWNTO 0) := x"AABBCCDDEEFF";
    CONSTANT MODULE_IP  : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"08080808";

BEGIN

    drop <= drop_reg;

    PROCESS(clock, reset)
    BEGIN
        IF reset = '1' THEN
            state <= IDLE;
            byte_cnt <= 0;
            icmp_cnt <= 0;
            in_ready <= '1';
            out_valid <= '0';
            out_sop <= '0';
            out_eop <= '0';
            out_data <= (OTHERS => 'X');
            drop_reg <= '0';
            src_mac_addr <= (OTHERS => '0');
            src_ip_addr  <= (OTHERS => '0');
            pkt_buffer <= (OTHERS => (OTHERS => '0'));

        ELSIF rising_edge(clock) THEN
            out_valid <= '0';
            out_sop   <= '0';
            out_eop   <= '0';
            out_data  <= (OTHERS => 'X');

            CASE state IS
                WHEN IDLE =>
                    byte_cnt <= 0;
                    icmp_cnt <= 0;
                    in_ready <= '1';
                    drop_reg <= '0';
                    IF in_valid = '1' AND in_sop = '1' THEN
                        pkt_buffer(0) <= in_data;
                        byte_cnt <= 1;
                        state <= ETHERNET_HEADER;
                    END IF;

                WHEN ETHERNET_HEADER =>
                    IF in_valid = '1' THEN
                        pkt_buffer(byte_cnt) <= in_data;
                        IF byte_cnt >= 6 AND byte_cnt <= 11 THEN
                            src_mac_addr <= src_mac_addr(39 DOWNTO 0) & in_data;
                        END IF;
                        IF byte_cnt = 13 THEN state <= IP_HEADER; END IF;
                        byte_cnt <= byte_cnt + 1;
                    END IF;

                WHEN IP_HEADER =>
                    IF in_valid = '1' THEN
                        pkt_buffer(byte_cnt) <= in_data;
                        IF byte_cnt = 18 THEN
                            IF unsigned(in_data) <= 1 THEN 
                                state <= PACKET_DROPPED;
                                drop_reg <= '1';  
                            ELSE 
                                state <= PACKET_PASSED;
                                drop_reg <= '0';
                            END IF;
                        END IF;
                        byte_cnt <= byte_cnt + 1;
                    END IF;

                WHEN PACKET_DROPPED =>
                    IF in_valid = '1' THEN
                        pkt_buffer(byte_cnt) <= in_data;
                        IF byte_cnt >= 20 AND byte_cnt <= 23 THEN
                            src_ip_addr <= src_ip_addr(23 DOWNTO 0) & in_data;
                        END IF;

                        IF in_eop = '1' THEN
                            state <= SEND_ICMP;
                            icmp_cnt <= 0;
                        END IF;
                        byte_cnt <= byte_cnt + 1;
                    END IF;

                WHEN SEND_ICMP =>
                    drop_reg <= '0';  
                    in_ready <= '0';
                    IF out_ready = '1' THEN
                        out_valid <= '1';
                        CASE icmp_cnt IS
                            WHEN 0 => out_sop <= '1'; out_data <= src_mac_addr(47 DOWNTO 40);
                            WHEN 1 => out_data <= src_mac_addr(39 DOWNTO 32);
                            WHEN 2 => out_data <= src_mac_addr(31 DOWNTO 24);
                            WHEN 3 => out_data <= src_mac_addr(23 DOWNTO 16);
                            WHEN 4 => out_data <= src_mac_addr(15 DOWNTO 8);
                            WHEN 5 => out_data <= src_mac_addr(7 DOWNTO 0);
                            WHEN 6 => out_data <= MODULE_MAC(47 DOWNTO 40);
                            WHEN 7 TO 11 => out_data <= MODULE_MAC(39 - (icmp_cnt-7)*8 DOWNTO 32 - (icmp_cnt-7)*8);
                            WHEN 12 => out_data <= x"08"; 
									 WHEN 13 => out_data <= x"00";
                            WHEN 14 => out_data <= x"45"; 
									 WHEN 15 => out_data <= x"00"; 
                            WHEN 16 => out_data <= x"3C";
									 WHEN 17 => out_data <= x"40"; 
                            WHEN 18 => out_data <= x"01"; 
                            WHEN 19 => out_data <= MODULE_IP(31 DOWNTO 24);
                            WHEN 20 => out_data <= MODULE_IP(23 DOWNTO 16);
                            WHEN 21 => out_data <= MODULE_IP(15 DOWNTO 8);
                            WHEN 22 => out_data <= MODULE_IP(7 DOWNTO 0);
                            WHEN 23 => out_data <= src_ip_addr(31 DOWNTO 24);
                            WHEN 24 => out_data <= src_ip_addr(23 DOWNTO 16);
                            WHEN 25 => out_data <= src_ip_addr(15 DOWNTO 8);
                            WHEN 26 => out_data <= src_ip_addr(7 DOWNTO 0);
                            WHEN 27 => out_data <= x"0B"; 
									 WHEN 28 => out_data <= x"00";
                            WHEN 29 TO 42 => 
                                out_data <= pkt_buffer(icmp_cnt - 15);
                                IF icmp_cnt = 42 THEN 
                                    out_eop <= '1'; 
                                    state <= IDLE; 
                                END IF;
                            WHEN OTHERS => state <= IDLE;
                        END CASE;
                        icmp_cnt <= icmp_cnt + 1;
                    END IF;

                WHEN PACKET_PASSED =>
                    IF in_valid = '1' AND in_eop = '1' THEN state <= IDLE; END IF;

                WHEN OTHERS => state <= IDLE;
            END CASE;
        END IF;
    END PROCESS;

END bhv;
