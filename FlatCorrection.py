# -*- coding: utf-8 -*-
"""
Created on Mon Oct 11 15:33:09 2021

@author: Sadeq Saleh
Reads the data from raw data, creates a new hdf file and normalize the data and
save it in uint8 type
"""
import sys
import h5py
import dxchange
import tomopy
import time
import numpy as np

def copy_skeleton(fname,outputname):
    with h5py.File(outputname,'w') as output:
        with h5py.File(fname,'r') as proj:
            try:
                proj.copy(proj['defaults'],output)
                proj.copy(proj['measurement'],output)
                proj.copy(proj['process'],output)
            except:
                print("Some data groups don't exist in the original projection")
            else:
                output.create_group('exchange')
                proj.copy('exchange/theta',output['exchange'])
        # Create a dataset like the original data but compressed in gZip format
                output.create_dataset_like('exchange/data',
                                            proj['exchange']['data'],
                                            compression="gzip")
        # enable these lines instead of dataset above with no data compression
                # output.create_dataset_like('exchange/data',
                #                            proj['exchange']['data'])
                #output.create_dataset_like('exchange/data_dark',proj['exchange']['data_dark'])
                #output.create_dataset_like('exchange/data_white',proj['exchange']['data_white'])
        length = len(output['exchange']['data'])
    return length

def flat_dark_correction(proj, flat, dark):
    proj = tomopy.normalize(proj,flat,dark)
    tomopy.minus_log(proj,out=proj)
    proj,_ = tomopy.prep.alignment.scale(proj)
    proj = proj*127+127    
    return proj.astype('uint8')

def return_(input):
    return input


if __name__ == "__main__":
    
    # fname = u"Z:\\s06_3d_205.h5"
    # darkname = u"Z:\\dark_fields_s06_3d_ethanol_157.h5"
    # flatname = u"Z:\\flat_fields_s06_3d_205.h5"
    # outputname = u"Y:\\s06\\s06_3d_205.h5"
    
    fname= sys.argv[1]
    # print(f"fname: {fname}")
    flatname= sys.argv[2]
    # print(f"flatname: {flatname}")
    outputname= sys.argv[3]
    # print(f"outputname: {outputname}")
    # start timing
    start_time = time.time()
    # Create a blank hdf file like the input file pre correction
    length = copy_skeleton(fname, outputname)
    
    print(str(length))

    _,flat,_,_ = dxchange.read_aps_2bm(flatname)
    # _,_,dark,_ = dxchange.read_aps_2bm(darkname)
    reshaped_dark = 3*np.ones_like(flat)
    # reshaped_dark[:dark.shape[0],:dark.shape[1],:dark.shape[2]]=dark
    
    chunk = 500
    step = 1
    with h5py.File(outputname,'r+') as output:
        output['exchange']['data_white'] = flat.astype('uint8')
        output['exchange']['data_dark'] = reshaped_dark.astype('uint8')
        for idx in range(0,length,chunk):
            start = idx
            if start + chunk > length:
                stop = length
            else:
                stop = start + chunk
            proj,_,_,_ = dxchange.read_aps_2bm(fname,proj = (start,stop,step))
            proj = flat_dark_correction(proj, flat, reshaped_dark)
            output['exchange']['data'][start:stop,:,:]=proj
            # print(f'chunk {stop:03} out of {length} has been corrected and written to the output hdf file.')
    # print ("--- %.1f seconds ---" % (time.time() - start_time))
    
    

        
    




