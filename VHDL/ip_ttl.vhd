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

    SIGNAL stored_dst_mac : STD_LOGIC_VECTOR(47 DOWNTO 0) := (OTHERS => '0');
    SIGNAL stored_src_mac : STD_LOGIC_VECTOR(47 DOWNTO 0) := (OTHERS => '0');
    SIGNAL src_ip_addr    : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

    SIGNAL drop_reg      : STD_LOGIC := '0';
    SIGNAL drop_helper   : STD_LOGIC := '0'; 

    CONSTANT MODULE_IP    : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"08080808";

BEGIN

    drop <= drop_reg;

    PROCESS(clock, reset)
    BEGIN
        IF reset = '1' THEN
            state <= IDLE;
            byte_cnt <= 0; icmp_cnt <= 0;
            in_ready <= '1';
            out_valid <= '0'; out_sop <= '0'; out_eop <= '0';
            out_data <= (OTHERS => '0');
            drop_reg <= '0';
            drop_helper <= '0';
        ELSIF rising_edge(clock) THEN
            out_valid <= '0'; out_sop <= '0'; out_eop <= '0';

            CASE state IS

                WHEN IDLE =>
                    byte_cnt <= 0; icmp_cnt <= 0;
                    in_ready <= '1';
                    drop_reg <= '0';
                    drop_helper <= '0';
                    IF in_valid = '1' AND in_sop = '1' THEN
                        pkt_buffer(0) <= in_data;
                        stored_dst_mac <= stored_dst_mac(39 DOWNTO 0) & in_data;
                        byte_cnt <= 1;
                        state <= ETHERNET_HEADER;
                    END IF;

                WHEN ETHERNET_HEADER =>
                    IF in_valid = '1' THEN
                        pkt_buffer(byte_cnt) <= in_data;
                        IF byte_cnt <= 5 THEN
                            stored_dst_mac <= stored_dst_mac(39 DOWNTO 0) & in_data;
                        ELSIF byte_cnt >= 6 AND byte_cnt <= 11 THEN
                            stored_src_mac <= stored_src_mac(39 DOWNTO 0) & in_data;
                        END IF;
                        IF byte_cnt = 14 THEN state <= IP_HEADER; END IF;
                        byte_cnt <= byte_cnt + 1;
                    END IF;

                WHEN IP_HEADER =>
                    IF in_valid = '1' THEN
                        pkt_buffer(byte_cnt) <= in_data;
                        IF byte_cnt = 18 THEN
                            IF unsigned(pkt_buffer(17)) <= 1 THEN
                                state <= PACKET_DROPPED;
                                drop_reg <= '1';
                            ELSE
                                state <= PACKET_PASSED;
                            END IF;
                        END IF;
                        byte_cnt <= byte_cnt + 1;
                    END IF;

                WHEN PACKET_DROPPED =>
                    IF in_valid = '1' THEN
                        pkt_buffer(byte_cnt) <= in_data;
                        IF byte_cnt >= 19 AND byte_cnt <= 22 THEN
                            src_ip_addr <= src_ip_addr(23 DOWNTO 0) & in_data;
                        END IF;

                        IF in_eop = '1' THEN
                            drop_helper <= '1';
                        END IF;
                        byte_cnt <= byte_cnt + 1;
                    END IF;

                    IF drop_helper = '1' THEN
                        state <= SEND_ICMP;
                        drop_reg <= '0';
                        icmp_cnt <= 0;
                        in_ready <= '0';
                    END IF;

                WHEN SEND_ICMP =>
                    IF out_ready = '1' THEN
                        out_valid <= '1';
                        CASE icmp_cnt IS
                            WHEN 0 TO 5 =>
                                IF icmp_cnt = 0 THEN out_sop <= '1'; END IF;
                                out_data <= stored_src_mac(47-(icmp_cnt*8) DOWNTO 40-(icmp_cnt*8));
                            WHEN 6 TO 11 =>
                                out_data <= stored_dst_mac(47-((icmp_cnt-6)*8) DOWNTO 40-((icmp_cnt-6)*8));
                            WHEN 12 => out_data <= x"08"; 
                            WHEN 13 => out_data <= x"00";
                            WHEN 14 => out_data <= x"45"; 
                            WHEN 15 => out_data <= x"00"; 
                            WHEN 16 => out_data <= x"3C"; 
                            WHEN 17 => out_data <= x"40"; 
                            WHEN 18 => out_data <= x"01"; 
                            WHEN 19 TO 22 => 
                                out_data <= MODULE_IP(31-((icmp_cnt-19)*8) DOWNTO 24-((icmp_cnt-19)*8));
                            WHEN 23 TO 26 => 
                                out_data <= src_ip_addr(31-((icmp_cnt-23)*8) DOWNTO 24-((icmp_cnt-23)*8));
                            WHEN 27 => out_data <= x"0B"; 
                            WHEN 28 => out_data <= x"00"; 
                            WHEN 29 TO 41 => 
                                out_data <= pkt_buffer(icmp_cnt - 15);
                                IF icmp_cnt = 41 THEN
                                    out_eop <= '1';
                                    byte_cnt <= 255; 
                                END IF;
                            WHEN OTHERS => NULL;
                        END CASE;
                        IF byte_cnt = 255 THEN
                            state <= IDLE;
                            byte_cnt <= 0;
                            icmp_cnt <= 0;
                            out_data <= (OTHERS => '0'); 
                            out_valid <= '0';
                        ELSE
                            icmp_cnt <= icmp_cnt + 1;
                        END IF;
                    END IF;
                WHEN PACKET_PASSED =>
                    IF in_valid = '1' AND in_eop = '1' THEN 
                        byte_cnt <= 255; 
                    END IF;

                    IF byte_cnt = 255 THEN
                        state <= IDLE;
                        byte_cnt <= 0;
                    END IF;

                WHEN OTHERS => 
                    state <= IDLE;
						  END CASE;
        END IF;
    END PROCESS;

END bhv;