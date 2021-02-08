clear all

%legge l'immagine della quale si vuole trascrivere il contenuto
I = imread('eng.png');

%usa l'ocr per trovare il testo presente
txt = ocr(I)
