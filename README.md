# IPv4_Time_to_Live_Mechanism

# Uvod
Mrežni sloj Interneta omogućava usluge transportnom sloju, dok istovremeno koristi usluge sloja veze podataka (engl. link layer). Mrežni sloj pruža usluge paketizacije i usmjeravanja paketa od izvora do odredišta. Glavno pitanje na mrežnom sloju je adresiranje. Za identifikaciju veze svakog uređaja s Internetom naziva se internet adresa ili IP adresa. IPv4 adresa sastoji se od 32 bita. IPv4 adrese su jedinstvene, odnosno svaka adresa definiše jednu i samo jednu vezu s Internetom. Ako uređaj ima dvije veze prema Internetu, preko dvije različite mreže, tada ima i dvije IPv4 adrese [1].
Ovaj projekat implementira IPv4 Time To Live (TTL) mehanizam u obliku hardverskog modula. Modul prima IPv4 pakete putem Avalon-ST interfejsa, dekrementira TTL polje i odlučuje da li se paket prosljeđuje ili odbacuje.

# IPv4 zaglavlje
Na slici 1 prikazano je IPv4 zaglavlje:

<p align="center">
  <img src="Graficki_prikaz/IPv4_header.png " width="500">
</p>
<p align="center">
  <em> Slika 1: IPv4 zaglavlje</em>
</p>



**Version = (4)**: Definiše verziju IPv4 protokola.

**IHL (Header Length)** : Označava ukupnu dužinu zaglavlja, koja je promjenjiva (između 20 i 60 bajta).

**Type of Service** : Označava prioritet i tip usluge paketa; prva tri bita definišu prioritet datagrama, dok naredna četiri bita označavaju tip usluge.

**Total Length** : Polje koje definiše dužinu zaglavlja zajedno sa podacima IPv4 datagrama u bajtovima.

**Time To Live (TTL)** : polje definiše maksimalan broj mrežnih čvorova.

**Identification** : Polje za identifikaciju fragmenata istog IPv4 paketa.

**Flags / Fragment Offset** : Polja za upravljanje fragmentacijom.

**Protocol** : 8-bitno polje koje definiše protokol višeg nivoa, npr.(ICMP), određuje konačni odredišni protokol kojem se IPv4 datagram isporučuje.

**Header Checksum** : Služi za provjeru ispravnosti IPv4 zaglavlja. 

**Source IP Address** : 32-bitno polje definiše IPv4 adresu izvora.

**Destination IP Address** : 32-bitno polje koje definiše IPv4 adresu odredišta [1].

# Time To Live (TTL) polje 
Definiše maksimalan broj obrade kroz koje IPv4 paket može proći. Prvobitno dizajniran da sadrži vremensku oznaku, koju bi smanjivao svaki postojeći ruter te  datagram bi bio odbačen kada vrijednost postane nula. Funkcija ovog polja je da se koristi za kontrolu maksimalnog broja skokova. Izvorišni host kada pošalje datagram, pohranjuje broj u ovo polje gdje je vrijednost približno 2 puta veća od maksimalnog broja ruta između bilo koja dva hosta. Vrijednost TTL-a se dekrementira prilikom obrade paketa. Ovo polje je značajno pri oštećenju tabele usmijeravanja na internetu. Polje ograničava vijek trajanja datagrama, gdje datagram može putovati dugo vremena između dva ili više rutera a da nikada ne dođe do odredišnog hosta. Druga funkcija polja je namjerno ograničenje putovanja paketa, te ga ograničiti na lokalnu mrežu.
U okviru ovog projekta, TTL modul prilikom prijema IPv4 paketa smanjuje TTL vrijednost za jedan. Ukoliko nakon dekrementacije TTL postane nula,paket se odbacuje, aktivira se signal `drop`, te se generiše ICMPv4
Time Exceeded poruka koja se šalje nazad pošiljaocu [1].

# Scenariji testiranja
**Scenarij 1 - TTL > 1**

U prvom testnom scenariju razmatra se obrada IPv4 paketa čija je vrijednost TTL polja veća od jedan. Pošiljalac (IP_PACKET_SENDER) formira Ethernet okvir u čijem se podatkovnom polju nalazi IPv4 paket, a Type polje označava da se radi o IPv4 protokolu. Nakon prijema paketa od strane primaoca (TTL_MODULE), obrađuje se IPv4 zaglavlje. Provjerava se TTL polje, te nakon što se utvrdi da TTL nije istekao, dekrementira se njegova vrijednost i paket se prosljeđuje dalje bez generisanja ICMP poruke.
Ovim scenarijom se potvrđuje da TTL modul ispravno obrađuje validne IPv4 pakete i omogućava njihov prolaz kroz sistem (Slika 2).

<p align="center">
  <img src="Graficki_prikaz/Scenarij1-ispravljen.jpg " width="500">
</p>
<p align="center">
  <em>Slika 2: Scenarij 1 - TTL > 1</em>
</p>

**Scenarij 2 - TTL = 1**

U drugom testnom scenariju razmatra se obrada IPv4 paketa kod kojeg je TTL vrijednost jednaka jedan.Nakon prijema Etherent okvira i izdvajanja IPv4 paketa, TTL_MODUL provjerava TTL polje i utvrđuje da bi njegovim umanjenjem došlo do nulte vrijednosti. Takav paket se esmatra nevažećim, te se odbacuje i generiše se ICMP Time Exceeded poruka. ICMP poruka se formira tako da sadrži informacije potrebne za identifikaciju odbačenog paketa, a šalje se nazad prema izvornoj adresi. Ovaj scenarij omogućava pravilnu detekciju isteka TTL vrijednosti i reakcije TTL modula u slučaju greške (Slika 3).

<p align="center">
  <img src="Graficki_prikaz/scenarij2.jpg " width="500">
</p>
<p align="center">
  <em>Slika 3: Scenarij 2 - TTL = 1</em>
</p>

# Opis ulaznih i izlaznih signala modula

| TIP | SIGNAL | IN/OUT | OPIS |
|-----|--------|--------|------|
| STD_LOGIC | clock | IN | Glavni takt signala |
| STD_LOGIC | reset | IN | Signal za reset sistema |
| STD_LOGIC_VECTOR(7 DOWNTO 0) | in_data | IN | Ulazni podaci (8-bitni) |
| STD_LOGIC | in_valid | IN | Indikator validnosti ulaznih podataka |
| STD_LOGIC | in_sop | IN | Početak paketa (Start Of Packet) |
| STD_LOGIC | in_eop | IN | Kraj paketa (End Of Packet) |
| STD_LOGIC | in_ready | OUT | Indikator spremnosti za primanje podataka |
| STD_LOGIC_VECTOR(7 DOWNTO 0) | out_data | OUT | Izlazni podaci (8-bitni) |
| STD_LOGIC | out_valid | OUT | Indikator validnosti izlaznih podataka |
| STD_LOGIC | out_sop | OUT | Početak izlaznog paketa |
| STD_LOGIC | out_eop | OUT | Kraj izlaznog paketa |
| STD_LOGIC | out_ready | IN | Signal da je primatelj spreman za podatke |
| STD_LOGIC | drop | OUT | Indikator odbačenog paketa, aktivan do kraja odbačenog paketa|

Za prikaz WaveDrom scenarija koriste se samo oni dijelovi paketa koji su definisani u scenarijima testiranja.

**TTL > 1**

Na slici 4 prikazan je WaveDrom za dolazni paket sa TTL > 1. Signal `in_valid` postaje aktivan(`1`) dok se podaci prenose. Početak paketa označen je sa signalom `in_sop`, a kraj paketa signalom `in_eop`, koji se aktivira na zadnjem taktu.
`out_data`,`out_sop`,`out_eop` i `out_valid` imaju vrijednost nula jer je vrijednost TTL polja veća od jedan te nema generisanja ICMP poruke. Signal `drop` ostaje neaktivan (`0`) tokom cijelog trajanja paketa jer modul ne odbacuje paket. Ulazni signali (`in_data`) objašnjeni su u nastavku:

*Ethernet zaglavlje*

Destiantion Address: 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF  
Source Address: 0x00 0x11 0x22 0x33 0x44 0x55  <br>
Type: 0x08 0x00 (IPv4)  

*IPv4 zaglavlje*

Version + IHL: 0x45  
Total Length: 0x00 0x3C <br>
TTL: 0x40 <br>
Protocol: 0x11 (UDP)  <br>
Source Address: 0xC0 0xA8 0x01 0x01  
Destination Address: 0x08 0x08 0x08 0x08  

<p align="center">
  <img src="WaveDrom/scenarij1.png " width="600">
</p>
<p align="center">
  <em>Slika 4: WaveDrom prikaz za  TTL>1 </em>
</p>

**TTL = 1**

Na slici 5 prikazan je WaveDrom za dolazni paket sa TTL=1. Signal `in_valid` ostaje aktivan(`1`) dok se podaci prenose. Početak paketa označen je sa signalom `in_sop`, a kraj paketa signalom `in_eop`, koji se aktivira na zadnjem taktu. 
Kako je vrijednost TTL=1, modul generiše ICMPv4 nakon što se proslijedi čitav paket. Signal `drop` postaje aktivan (`1`) nakon provjere TTL polja i ostaje aktivan do kraja trajanja paketa. Ulazni signali (`in_data`) objašnjeni su u nastavku:

*Ethernet zaglavlje*  

Destination Address: 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF  
Source Address: 0x00 0x11 0x22 0x33 0x44 0x55  
Type: 0x08 0x00 (IPv4)  

*IPv4 zaglavlje*

Version + IHL: 0x45  
Total Length: 0x00 0x3C  <br>
TTL: 0x01 <br>
Protocol: 0x11 (UDP)  <br>
Source Address: 0xC0 0xA8 0x01 0x01  
Destination Address: 0x08 0x08 0x08 0x08  

`out_sop`,`out_eop` i `out_valid` prate izlazni paket. Izlazni signali (`out_data`) objašnjeni su u nastavku:

*Ethernet zaglavlje*

Destination Address: 0x00 0x11 0x22 0x33 0x44 0x55 <br>
Source Address: 0xAA 0xBB 0xCC 0xDD 0xEE 0xFF <br>
Type: 0x08 0x00 (IPv4)  

*IPv4 zaglavlje* 

Version + IHL: 0x45<br>
Total Length: 0x00 0x3C<br> 
TTL: 0x40<br> 
Protocol: 0x01 (ICMP)<br> 
Source Address: 0x08 0x08 0x08 0x08<br>
Destination Address: 0xC0 0xA8 0x01 0x01 

*ICMP zaglavlje*

Type: 0x0B (Time Exceeded) <br>
Code: 0x00  <br>
Data: 0x45 0x00 0x3C 0x01 0x11 0xC0 0xA8 0x01 0x01 0x08 0x08 0x08 0x08  

<p align="center">
  <img src="WaveDrom/S2.png " width="800">
</p>
<p align="center">
  <em>Slika 5: WaveDrom prikaz za  TTL=1 </em>
</p>

# FSM dijagram
 **IDLE** stanje govori da je modul `ip_ttl` spreman za prijem novog paketa (`in_valid && in_sop`) i javlja se nakon aktivacije signala `reset`. Nakon detekecije početka paketa (`in_valid==1 && in_sop==1`), FSM prelazi u stanje **ETHERNET_HEADER** gdje se čita destinacijska adresa i Type. Slijedi stanje **IP_HEADER**, gdje se vrši obrada bajtova sve dok brojač ne dostigne vrijednost 18, što je pozicija TTL polja. Na tom mjestu se vrši provjera upotrebom *unsigned(in_data)*: ako je vrijednost veća od jedan, paket se smatra validnim i automat prelazi u stanje **PACKET_PASSED**, dok se u slučaju vrijednosti jedan FSM prelazi u stanje **PACKET_DROPPED**. U oba slučaja sistem prati dolazni tok podataka sve do detekcije signala `in_eop` koji označava kraj paketa. U završnom stanju **SEND_ICMP**, modul generiše ICMP Time Exceeded poruku. Slanje se vrši sinhronizovano sa signalom `out_ready`. Nakon što je cijela ICMP poruka poslana, FSM se vraća u stanje IDLE.
<p align="center">
  <img src="FSM/FSM.jpg " width="500">
</p>
<p align="center">
  <em>Slika 6: FSM dijagram </em>
</p> 

# Time To Live Mechanism - VHDL modul
## Opis *ip_ttl* modula
Modul `ip_ttl` implementira osnovnu provjeru TTL polja IPv4 paketa i generisanje ICMP Time Exceeded poruke kada TTL dosegne vrijednost 1. Logika je realizovana sekvencijalno kroz FSM sa jasno definisanim stanjima: IDLE, ETHERNET_HEADER, IP_HEADER, PACKET_PASSED, PACKET_DROPPED i SEND_ICMP.
# Literatura
[1] B. A. Forouzan, Data Communications and Networking, 5th ed., New York: McGraw-Hill, 2013, str. 511, 528-529, 562-566

