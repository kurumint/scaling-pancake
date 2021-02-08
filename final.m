clear all 

%legge l'immagine della quale si vuole trascrivere il contenuto
I = imread('alph.png');

%porta tale immagine a scala di grigi
I = rgb2gray(I);

%operatore bottom hat per estrarre il testo (scuro) dallo sfondo (chiaro)
e = strel('disk', 5);
I = imbothat(I, e);

%sogliatura con otsu e binarizzazione dell'immagine
T = graythresh(I);
I = imbinarize(I, T);

%vengono prese le singole lettere
stats = regionprops(I, 'BoundingBox');

%in fase di acquisizione, non è detto che tutte le boundingbox trovate
%abbiano la stessa area. per questo motivo, ognuna viene ridimensionata a
%16x16. 

%viene creata una matrice per contenere le singole lettere in cui ogni riga
%corrisponde ad una lettera. per visualizzarne una, è necessario fare
%imshow della riga "reshaped" a 16x16. 
textletters = zeros(0,256);
for i = 1 : length(stats)
    BB = stats(i).BoundingBox;
    newletter = imcrop(I,[BB(1), BB(2), BB(3), BB(4)]);
    resizedletter = imresize(newletter, [16,16]);
    finalletter = reshape(resizedletter, 1, 256);
    textletters = [textletters; double(finalletter)];
end 

%costruzione del "database" contenente le lettere su cui baseremo il
%confronto.
%le operazioni effettuate sono simili a quelle effettuate per l'immagine
%che vogliamo analizzare. 
alphabet = imread('upper.png');
alphabet = rgb2gray(alphabet);
alphabet = imbothat(alphabet, e);
Ta = graythresh(alphabet);
alphabet = imbinarize(alphabet, Ta);
astats = regionprops(alphabet, 'BoundingBox');

%dato che nell'immagine l'alfabero è distribuito su più righe, bisogna
%ordinare opportunamente le boundingbox per ottenere una lettura
%sinistra->destra, alto->basso. 
apositions = zeros(0,6);
for i = 1 : length(astats)
    BB = astats(i).BoundingBox;
    apositions = [apositions; [BB(1), BB(2), BB(3), BB(4), BB(1)+BB(3), BB(2)+BB(4)]];
end
anewpositions = sortrows(apositions, [6 5 2 1]);

database = zeros(0,256);
for i = 1 : length(astats)
    newletter = imcrop(alphabet,[anewpositions(i,1), anewpositions(i,2), anewpositions(i,3), anewpositions(i,4)]);
    resizedletter = imresize(newletter, [16,16]);
    finalletter = reshape(resizedletter, 1, 256);
    database = [database; double(finalletter)];
end

%costruisco una matrice m tale che m_ij rappresenti la distanza della i-esima
%lettera da classificare rispetto alla j-esima lettera presente nel
%database. ogni riga, quindi, contiene tutte le distanze della i-esima
%lettera da tutte quelle del database. 
m = zeros(length(stats), length(astats));
for i = 1 : length(stats)
    for j = 1 : length(astats)
        i_row_letters = textletters(i,:);
        j_row_database = database(j,:);
        m(i,j)  = sqrt(sum((i_row_letters - j_row_database) .^ 2));
    end
end

%ad ogni lettera verrà associata la corrispondente appartenente al database
%rispetto alla quale ha minore distanza.
[minValues, minIndices] = min(m,[],2);

%il risultato viene stampato
s = 'ABCDEFGHIJKLMNOPRSTUVWXYZQ';
for i = 1 : length(stats)
    fprintf(s(minIndices(i,1)));
end
fprintf('\n');
