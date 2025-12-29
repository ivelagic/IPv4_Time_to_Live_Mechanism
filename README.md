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

U drugom testnom scenariju razmatra se obrada IPv4 paketa kod kojeg je TTL vrijednost jednaka jedan.Nakon prijema Etherent okvira i izdvajanja IPv4 paketa, TTL_MODUL provjerava TTL polje i utvrđuje da bi njegovim umanjenjem došlo do nulte vrijednosti. Takav paket se esmatra nevažećim, te se odbacuje i generiše se ICMP Time Exceeded poruka.ICMP poruka se formira tako da sadrži informacije potrebne za identifikaciju odbačenog paketa, a šelje se nazad prema izvornoj adresi. Ovaj scenarij omogućava pracilnu detekciju isteka TTL vrijednosti i reakcije TTL modula u slučaju greške (Slika 3).

<p align="center">
  <img src="Graficki_prikaz/Scenarij_2-ispravljen.jpg " width="500">
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

**TTL > 1**

Na slici 4 prikazan je WaveDrom za dolazni paket sa TTL > 1. Ulazni signal je `in_data` gdje je prvi bajt `in_data = 01000101` IPv4 header, a drugi `in_data=01000000` TTL (64). Signal `in_valid` postaje aktivan(`1`) dok se podaci prenose. Početak paketa označen je sa signalom `in_sop`, a kraj paketa signalom `in_eop`, koji se aktivira na zadnjem taktu.
`out_data` ima istu vrijednost kao `in_data`, a `out_sop`,`out_eop` i `out_valid` prate ulazne signale. Signal `drop` ostaje neaktivan (`0`) tokom cijelog trajanja paketa jer modul ne odbacuje paket.

<p align="center">
  <img src="WaveDrom/scenarij1.png " width="500">
</p>
<p align="center">
  <em>Slika 4: WaveDrom prikaz za  TTL>1 </em>
</p>

**TTL = 1**

Na slici 5 prikazan je WaveDrom za dolazni paket sa TTL =1 1. Ulazni signal je `in_data` gdje je prvi bajt `in_data = 01000101` IPv4 header, a drugi `in_data=00000001` TTL (1). Signal `in_valid` ostaje aktivan(`1`) dok se podaci prenose. Početak paketa označen je sa signalom `in_sop`, a kraj pakeata signalom `in_eop`, koji se aktivira na zadnjem taktu. 
Kako je vrijdnost TTL=1 mogul generiše ICMPv4 Time Exceeded poruku. `out_data` šalje bajtove ICMP poruke: `10001100` označava Type (`11`), `00000000` Code (`0`). `out_sop` i `out_eop` prate ICMP paket. `out_valid` aktivan je sve vrijeme. Signal `drop` postaje aktivan (`1`) tokom trajanja ICMP paketa jer modul odbacuje paket.

<p align="center">
  <img src="WaveDrom/scenarij2.png " width="500">
</p>
<p align="center">
  <em>Slika 5: WaveDrom prikaz za  TTL=1 </em>
</p>

# FSM dijagram
**Idle** stanje govori da je modul `ip_ttl` spreman za prijem novog paketa (`in_valid=1`), a javlja se nakon aktivacije signala `reset`. Nakon detekecije početka paketa (`in_valid=1 & in_sop=1`) FSM prelazi u stanje provjere vrijednosti TTL-a. Ukoliko je TTL>1 FSM prelazi u stanje **Packet Passed**, signal `drop` ostaje nekativan, a izlazni signali prate izlazne. FSM ostaje u ovom stanju sve do kraja paketa (`in_eop`=1), nakon čega se vraća u stanje Idle. Za slučaj kada je TTL=1 FSM prelazi u stanje **Packet Dropped Send ICMP**, gdje se aktivira signal `drop` i paralelno aktivira ICMPv4Exceeded poruka. Nakon kraja paketa `in_eop=1` vraća se u početno stanje. Na slici 6 prikazan je FSM dijagram.
<p align="center">
  <img src="FSM/FSM.jpg " width="500">
</p>
<p align="center">
  <em>Slika 6: FSM dijagram </em>
</p>

# Literatura
[1] B. A. Forouzan, Data Communications and Networking, 5th ed., New York: McGraw-Hill, 2013, str. 511, 528-529, 562-566

