clc
clear variables
clear all

#{

Tämän tarkoitus on puhdistaa taulukko, joka koostuu koskemattomasta tuotantodatasta.
Skripti poistaa nolla- ja NaN-arvot. Lisäksi se poistaa outlierit käyttämällä
interkvarttaali menetelmää. Poistettujen arvojen tyhjät välit interpoloidaan.
interpoloidaan. Lopuksi data suodatetaan liukuvallakeskiarvolla, jotta
datan inlierit ja värähtely saadaan poistettua.

Oletukset:
#1. Datan arvot on suhteellisen lähellä toisiaan.
    - Esim. Tilanteessa jossa on lämpötiloja ja milli bareja kannattaa luoda uusi
      toleranssi, jotta molempien muuttujien mittaus virheet huomioidaan.
    - Tällöin pitää myös luoda tapa jolla voidaan erottaa muuttujat toisistaan.
      Esim. Jos luku on alle 10 kyseessä on paine ja tällöin käytetään paineen toleranssia.
      Ja jos yli 10 niin silloin käytetään lämpötilan toleranssia. Tämä tietenkin
      riippuu datasta ja datan käsitteliästä miten tälläisissä tilanteissa toimitaan.
#2. Ensimmäinen sarake sisältää mittausajat.
    - Aika otetaan erotellaan muusta datasta ja yleensä se on ensimmäisessä sarakkeessa.
#3. Sarakkeen ensimmäinen ja viimeinen arvo ei ole nolla-arvo.
#4. Sarakkeen ensimmäinen ja viimeinen arvo ei ole NaN-arvo.
#5. Sarakkeen ensimmäinen ja viimeinen arvo ei ole outlieri.
    - Interpolaatio ei toimi oikein, jos ensimmäinen tai viimeine arvo on poikkeus.
    - Muokkaamalla ensimmäinen ja viimeinen arvo listan olemassa olevien lukujen
      keskiarvoksi, voidaan varmistaa, että lista täyttää oletukset.

#}

%%DATA
importattu_data = importaa_data; %Tähän lisätään haluttu data

data_aika = importattu_data(:,1); %Erotellaan aika.
data = importattu_data(:,2:end); %Otetaan kaikki muut paitsi aika.
[rivit, sarakkeet] = size(data); %Taulukon koko


%Toleranssit
%Säädä datan mukaan
toleranssi_1 = 3; %Pieni data arvo, joka ei ole mittaushäiriötä
liukuva_KA = 100; %liukuvan keskiarvon pituus

%Premade listat
nollat = zeros(rivit, sarakkeet);



%%Nolla-arvojen poistaminen
%tarkastaa nolla-arvojen määrän
for i = 1:sarakkeet
  nollat(:,i) = abs(data(:,i)) < toleranssi_1; %Nolla-arvo = 1 ja ei-nolla-arvo = 0
end
nolla_Maara_Ennen = sum(nollat(:)) %ilmoittaa nollien määrän

%Muuttaa jokaisen nolla arvon NaN arvoksi.
for i = 1:sarakkeet
  data((abs(data(:,i)) < toleranssi_1,i) = NaN;
end

%tarkastetaan nollien määrä uudelleen
nollat = data == 0;
nolla_maara_Jalkeen = sum(nollat(:)) %pitäisi olla 0



%%NaN-arvojen poisto
%Tarkastaa NaN-arvojen määrän
onNaN = isnan(data);
NaN_Maara_Ennen = sum(onNaN(:))

%Poistaa NaN-arvot
for i = 1:sarakeet
  x = data(:,i); %Tutkittava sarake
  t = data_aika; %Mittaus ajat

  onNaN = isnan(x); %löytää kaikki NaN-arvot

  x(onNaN) = []; %poistaa kaikki NaN-arvot
  aika = t(~onNaN) %poistaa kaikki NaN arovjen aikakohdat

  [uniikki_aika, idx] = unique(aika, 'stable'); %poistaa duplikaatit ja säilyttää järjestyksen
  uniikki_sarake = x(idx); %vastaavat sarakkeet

  x = interp1(uniikki_aika, uniikki_sarake, t, "linear", "extrap"); %interopoloi välit lineaarisesti
  data(:,i) = x; %tallentaa pudistetun sarakkeen dataan.
end

%Tarkastaa NaN-arvojen määrän
onNaN = isNaN(data);
NaN_Maara_Jalkeen = sum(onNaN(:)) %Pitäs olla 0



%%Outlierin poisto
%interkvartaali menetelmä
for i = 1:sarakeet
  x = data(:,i) %Tutkittava sarake
  t = data_aika; %Mittaus ajat

  Q1 = quantile(x,0.25); %Alakvarttaali
  Q3 = quantile(x, 0.75) %Yläkvarttaali
  IQR = Q3 - Q1; %interkvarttaaliväli
  outlier = (x < Q1 - 1.5*IQR | x > Q3 + 1.5*IQR); %määrittelee outlierin

  x(outlier) = []; %Poistaa outlierin
  aika = t(~outlier); %Poistaa outlierien ajankohdat

  [uniikki_aika, idx] = unique(aika, 'stable'); %poistaa duplikaatit ja säilyttää järjestyksen
  uniikki sarake = x(idx); %vastaavat sarakkeet

  x = interp1(uniikki_aika, uniikki_sarake, t, "linear", "extrap"); %interpoloi välit lineaarisesti
  data(:,i) = x; %tallentaa puhdistetun sarakkeen dataan
end


%%Datan suodatus liukuvalla keskiarvolla
for i = 1:sarakeet
  data(:,i) = movmean(data(:,i),liukuva_KA)
end

