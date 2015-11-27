function renameMRIFolders(folder)
% RENAMEMRIFOLDERS Renames MRI-Dicom folders to more understandable names.
%
% Usage:  renameMRIFolders(folder)
%
% Input:  folder wich contains the folder to be renamed.
%
% Output: none
%
% JA Disselhorst, Uni. Tuebingen.
% v20130402
%
    a = dir(folder); a = a([a.isdir]); a(1:2) = [];
    a = sort({a.name});
    for ii = 1:length(a)
        name = a{ii};
        if strfind(name,'fair_trufi_cscan_m0'), newname = 'ASL_m0'; 
        elseif strfind(name,'fair_trufi_cscan_meas'), newname = 'ASL_meas'; 
        elseif strfind(name,'se_mc_MapT2_pre'), newname = 'MapT2_pre'; 
        elseif strfind(name,'se_mc_MapT2_post'), newname = 'MapT2_pst'; 
        elseif strfind(name,'gre_mc_MapT2s_pre'), newname = 'MapT2s_pre'; 
        elseif strfind(name,'gre_mc_MapT2s_post'), newname = 'MapT2s_pst'; 
        elseif strfind(name,'haste_sag_phase'), newname = 'Haste'; 
        elseif strfind(name,'t2_tse3d_iso0p22'), newname = 'Anatomy';
        elseif strfind(name,'localizer'), newname = 'Localizer';
        elseif strfind(name,'fl3d_vibe_iso0p57_ATT'), newname = 'AttenCorr';
        elseif strfind(name,'t2_tse_cor_dy_6_40Aufn'), newname = 'Dynamic';
        else newname = 'NA';
        end
        
        N = 0;
        if exist(fullfile(folder,newname),'dir'); 
            newname = [newname '_02']; N = 3; 
        end
        while exist(fullfile(folder,newname),'dir');
            newname = sprintf('%s_%02.0f',newname(1:end-3),N);
            N = N+1;
        end
        if N && strcmpi(newname(1:end-3),'Haste')
            newname = 'Haste';
        end
        if N && strcmpi(newname(1:end-3),'Localizer')
            newname = 'Localizer';
        end
        if ~strcmp(newname,'NA')
            oldFolder = fullfile(folder,name);
            files = dir(fullfile(oldFolder,'*'));
            files = files(~[files.isdir]);
            for jj = 1:length(files);
               try
                   if ~exist(fullfile(folder,newname),'dir')
                       mkdir(fullfile(folder,newname));
                   end
                   movefile(fullfile(folder,name,files(jj).name),fullfile(folder,newname,files(jj).name));
               catch
                   fprintf('Error copying %s\n', fullfile(folder,name,files(jj).name))
               end
            end
            try 
                rmdir(fullfile(folder,name)); % Only removes the folder when it is empty.
            end
        end

    end
end
