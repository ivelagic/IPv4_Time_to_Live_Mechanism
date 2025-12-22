# IPv4_Time_to_Live_Mechanism

# Uvod
Mrežni sloj Interneta omogućava usluge transportnom sloju, dok istovremeno koristi usluge sloja veze podataka (engl. link layer). Mrežni sloj pruža usluge paketizacije i usmjeravanja paketa od izvora do odredišta. Glavno pitanje na mrežnom sloju je adresiranje. Za identifikaciju veze svakog uređaja s Internetom naziva se internet adresa ili IP adresa. IPv4 adresa sastoji se od 32 bita. IPv4 adrese su jedinstvene, odnosno svaka adresa definiše jednu i samo jednu vezu s Internetom. Ako uređaj ima dvije veze prema Internetu, preko dvije različite mreže, tada ima i dvije IPv4 adrese [1].
Ovaj projekat implementira IPv4 Time To Live (TTL) mehanizam u obliku hardverskog modula. Modul prima IPv4 pakete putem Avalon-ST interfejsa, dekrementira TTL polje i odlučuje da li se paket prosljeđuje ili odbacuje.

# IPv4 zaglavlje
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


# Literatura
[1] B. A. Forouzan, "Data Communications and Networking," 5th ed., New York: McGraw-Hill, 2013, ISBN 978-0-07-337622-6.
