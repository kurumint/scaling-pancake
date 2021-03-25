clear all 
close all

%legge l'immagine della quale si vuole trascrivere il contenuto
I = imread('eng.png');
%I = imread('gradient.png');

%I = imnoise(I,'gaussian', 0.8, 0.2);
%I = imnoise(I,'salt & pepper', 0.025);
%I = imrotate(I, 5);

originale = I;
figure, imshow(I);
%imwrite(I,'0.png');

%porta tale immagine a scala di grigi
I = rgb2gray(I);
%figure, imshow(I);
%imwrite(I,'1.png');

%operatore bottom hat per estrarre il testo (scuro) dallo sfondo (chiaro)
e = strel('disk', 7);
I = imbothat(I, e);
%figure, imshow(I);
%imwrite(I,'2.png');

%sogliatura con otsu e binarizzazione dell'immagine
T = graythresh(I);
I = imbinarize(I, T);
%figure, imshow(I);
%imwrite(I,'3.png');

copia = I;

%noise reduction
x = [0 1 1 1 0; 1 1 1 1 1; 0 1 1 1 0];
y = [1 1 1 1 ; 1 1 1 1; 1 1 1 1];
I = imdilate(I,x);
I = imerode(I,y);
%figure, imshow(I);
%imwrite(I,'4.png');

I = wiener2(I,[3 3]);
%figure, imshow(I);
%imwrite(I,'5.png');

%vengono trovate le linee con la trasformata di hough
[H,theta,rho] = hough(I);
peaks = houghpeaks(H,1);
lines = houghlines(I,theta,rho,peaks);

%ci interessa l'angolo più frequente di queste linee (che sarebbe l'angolo
%di cui è ruotata l'immagine). prendendo il primo supponiamo che tutte
%abbiano lo stesso angolo all'interno dell'immagine
angle = lines(1).theta;
correction_angle = 0;
if angle > 0
    correction_angle = angle - 90;
elseif angle < 0
    correction_angle = 90 + angle;
end

if angle ~= 0
    I = imrotate(I, correction_angle);
end
%figure, imshow(I);
%imwrite(I,'6.png');

%vengono prese le singole lettere
stats = regionprops(I, 'BoundingBox', 'Area');

%in fase di acquisizione, non è detto che tutte le boundingbox trovate
%abbiano la stessa area (soprattutto in un caso in cui siano presenti sia
%upper case che lower case). per questo motivo, ognuna viene ridimensionata
%a 16x16. 

%viene creata una matrice per contenere le singole lettere in cui ogni riga
%corrisponde ad una lettera. per visualizzarne una, è necessario fare
%imshow della riga "reshaped" a 16x16. 
letters = [];
textletters = zeros(0,256);

area = [stats.Area];
mean = mean(area);

%figure, imshow(I)
%hold on
%for i = 1 : length(stats)
%    BB = stats(i).BoundingBox;
%    rectangle('Position', [BB(1), BB(2), BB(3), BB(4)],'EdgeColor','r', 'LineWidth', 3)
%end

realboxes = [];
rletters = [];
for i = 1 : length(stats)
    %se l'area della bounding box è molto minore della dimensione media,
    %probabilmente abbiamo preso rumore e non una vera lettera, passiamo
    %avanti
    if stats(i).Area > 0.5*mean
        BB = stats(i).BoundingBox;
        newletter = imcrop(I,[BB(1), BB(2), BB(3), BB(4)]);
        realboxes{end+1} = [BB(1), BB(2), BB(3), BB(4)];
        letters{end+1} = newletter;
        resizedletter = imresize(newletter, [16,16]);
        rletters{end+1} = resizedletter;
        finalletter = reshape(resizedletter, 1, 256);
        textletters = [textletters; double(finalletter)];
    end
end 

%figure, imshow(I)
%hold on
%for i = 1 : length(realboxes)
%    rectangle('Position', realboxes{i},'EdgeColor','r', 'LineWidth', 3)
%end

%figure
%for i = 1 : size(letters, 2)
%    subplot(1,size(letters, 2),i);
%    imshow(letters{i});
%end

%figure
%for i = 1 : size(rletters, 2)
%    subplot(1,size(rletters, 2),i);
%    imshow(rletters{i});
%end

%
%
%

%costruzione del "database" contenente le lettere su cui baseremo il
%confronto. 
alphabet = imread('upper.png');
alphabet = rgb2gray(alphabet);
alphabet = imbothat(alphabet, e);
Ta = graythresh(alphabet);
alphabet = imbinarize(alphabet, Ta);
alphabet = wiener2(alphabet,[3 3]);

astats = regionprops(alphabet, 'BoundingBox');

%dato che nell'immagine l'alfabeto è distribuito su più righe, bisogna
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
tldim = size(textletters,1);
m = zeros(tldim, length(astats));
for i = 1 : tldim
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
output = "";
for i = 1 : tldim
    output = strcat(output,s(minIndices(i,1)));
end
output
fprintf('\n');

%misuriamo la distanza di edit tra la stringa vera e quella ottenuta
real = "THEQUICKBROWNFOXJUMPSOVERTHELAZYDOG";
distanza = editDistance(real,output)
normalized = distanza/max([strlength(real), strlength(output)])

txt = ocr(originale)
confronto = 'THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG';
d_ocr = editDistance(txt.Text,confronto)-2
n_ocr = d_ocr/max([strlength(txt.Text), strlength(confronto)])