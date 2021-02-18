clear all
georgia = imread('georgia.png');
georgia = rgb2gray(georgia);
e = strel('disk', 3);
georgia = imbothat(georgia, e);
tg = graythresh(georgia);
georgia = imbinarize(georgia, tg);
gstats = regionprops(georgia, 'BoundingBox', 'Centroid');
%imshow(georgia)
%hold on
%for k = 1 : length(gstats)
%     BB = gstats(k).BoundingBox;
%     rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','g','LineWidth',2) ;
%end
database = zeros(0,256);

% suppose 's' is the struct array. 'DOB' is the field that contains date and time.
%T = struct2table(gstats); % convert the struct array to a table
%sortedT = sortrows(T, gstats.BoundingBox{2}); % sort the table by 'DOB'
%gstats = table2struct(sortedT) % change it back to struct array if necessary

%il quinto e sesto valore è il punto in cui "finisce" la bounding box, che è quello
%secondo il quale vorrei ordinare 
positions = zeros(0, 8);
for i = 1 : length(gstats)
    BB = gstats(i).BoundingBox;
    c = gstats(i).Centroid;
    positions = [positions; [BB(1), BB(2), BB(3), BB(4), BB(1)+BB(3), BB(2)+BB(4), c(1), c(2)]];
end
newpositions = sortrows(positions, [6 5 2 1]);
%newpositions = sortrows(positions, [7 8]);

%singoleimm = []
j = 0;
for k = 1 : length(gstats)
    j = j+1;
    newletter = imcrop(georgia,[newpositions(k,1), newpositions(k,2), newpositions(k,3), newpositions(k,4)]);
    
    resizedletter = imresize(newletter, [16,16]);
    %singoleimm{end+1} = newletter;
    finalletter = reshape(resizedletter, 1, 256);
    if j == 25
        prova = finalletter;
    end
    database = [database; double(finalletter)];
end
%imshow(singoleimm{1, 73})
imshow(reshape(prova, 16,16));

%[gcoeff,gscore,glatent,gtsquared,gexplained,gmu] = pca(database);
%reduceddatabase = gscore(:,1:64);

%imshow(georgia);