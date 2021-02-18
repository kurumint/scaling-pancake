clear all

%legge l'immagine della quale si vuole trascrivere il contenuto
I = imread('eng.png');
%I = imread('italic.png');

%I = imnoise(I,'gaussian');
%I = imnoise(I,'salt & pepper');
%I = imtransform(I,maketform('affine',[1 0 0; .5 1 0; 0 0 1]));

imshow(I);

%usa l'ocr per trovare il testo presente
txt = ocr(I)
