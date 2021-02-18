clear all 

%legge l'immagine
I = imread('prova.png');

%porta l'immagine a scala di grigi
I = rgb2gray(I);

%mostra l'immagine
%imshow(I);

%elemento strutturante
%e = strel('square', 2);

%chiusura + apertura
%I = imopen(I, e);
%I = imclose(I, e);

%operatore bottom hat per estrarre il testo (scuro) dallo sfondo (chiaro)
e = strel('disk', 3);
I = imbothat(I, e);

%imshow(I);

%sogliatura con otsu e binarizzazione dell'immagine
T = graythresh(I);
I = imbinarize(I, T);

%imshow(I);

%vengono riconosciute le singole lettere
stats = regionprops(I, 'BoundingBox');

%disegna un rettangolo attorno a ogni lettera
%imshow(I)
hold on
for k = 1 : length(stats)
     BB = stats(k).BoundingBox;
     %rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','g','LineWidth',2) ;
end

%conserva i ritagli di immagine contenenti la singola lettera in una
%matrice (ogni riga rappresenta una lettera, che per essere visualizzata
%deve essere reshaped a 16x16, le 256 colonne rappresentano le features)
positions = zeros(0,6);
for i = 1 : length(stats)
    BB = stats(i).BoundingBox;
    positions = [positions; [BB(1), BB(2), BB(3), BB(4), BB(1)+BB(3), BB(2)+BB(4)]];
end
newpositions = sortrows(positions, [6 5 2 1]);

letters = zeros(0,256);
for k = 1 : length(stats)
    newletter = imcrop(I,[newpositions(k,1), newpositions(k,2), newpositions(k,3), newpositions(k,4)]);
    resizedletter = imresize(newletter, [16,16]);
    finalletter = reshape(resizedletter, 1, 256);
    letters = [letters; double(finalletter)];
end 

%si effettua la PCA per ridurre la dimensionalità e permettere un confronto
%col database di lettere più rapido ed efficiente 
%coeff = pca(letters);
[coeff,score,latent,tsquared,explained,mu] = pca(letters);

%tenere le prime 64 componenti (rispetto a 256) ci permette di mantenere il 99.9%
%dell'informazione
precisione = 0;
for i = 1 : 64
    precisione = precisione + explained(i, 1);
end

%teniamo allora le prime 64 componenti 
reduceddimension = score(:,1:64);

%adesso le nostre lettere da classificare sono pronte per essere
%confrontate con una misura di distanza (es. euclidea o distanza del
%coseno) rispetto al database che contiene le entries (26 uppercase + 26
%lowercase + 10 cifre + simboli), anch'esse 64-dimensionali, per trovare quella con
%minore distanza. 

%creiamo il nostro database, compiendo lo stesso lavoro sull'immagine che
%contiene tutti i caratteri del font 
georgia = imread('georgia.png');
georgia = rgb2gray(georgia);
georgia = imbothat(georgia, e);
tg = graythresh(georgia);
georgia = imbinarize(georgia, tg);
gstats = regionprops(georgia, 'BoundingBox');
database = zeros(0,256);

gpositions = zeros(0,6);
for i = 1 : length(gstats)
    BB = gstats(i).BoundingBox;
    gpositions = [gpositions; [BB(1), BB(2), BB(3), BB(4), BB(1)+BB(3), BB(2)+BB(4)]];
end
gnewpositions = sortrows(gpositions, [6 5 2 1]);

for k = 1 : length(gstats)
    newletter = imcrop(georgia,[gnewpositions(k,1), gnewpositions(k,2), gnewpositions(k,3), gnewpositions(k,4)]);
    resizedletter = imresize(newletter, [16,16]);
    finalletter = reshape(resizedletter, 1, 256);
    database = [database; double(finalletter)];
end
[gcoeff,gscore,glatent,gtsquared,gexplained,gmu] = pca(database);
reduceddatabase = gscore(:,1:64);

%se c'è match con la prima riga, allora si tratta di "A", con la seconda di
%"a", ecc. 

%costruisco una matrice tale che m_ij rappresenta la distanza dalla i-esima
%lettera da classificare rispetto alla j-esima lettera presente nel
%database. ogni riga, quindi, contiene tutte le distanze della i-esima
%lettera da tutte quelle del database. per la classificazione, si prende la
%colonna con valore minore e se ne guarda l'indice. 
D = zeros(length(stats), length(gstats));
for i = 1 : length(stats)
    for j = 1 : length(gstats)
        D(i,j)  = sqrt(sum((reduceddimension(i) - reduceddatabase(j)) .^ 2));
    end
end

[minValues, minIndices] = min(D,[],2);
for i = 1 : length(stats)
    alfabeto = '..AaBbCcDdEeFfGHhIiJKkLlMmNngjOoPRrSsTtUuVvWwXxYZzQpqy..!?126780...,,34579//////';
    fprintf(alfabeto(minIndices(i,1)));
end
