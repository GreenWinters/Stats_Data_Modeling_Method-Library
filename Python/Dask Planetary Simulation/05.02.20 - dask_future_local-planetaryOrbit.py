# -*- coding: utf-8 -*-
"""
Created on Mon Mar 30 11:25:46 2020

#Uses Futures

@author: Green Winters
Source Code Reference: https://fiftyexamples.readthedocs.io/en/latest/gravity.html
https://github.com/akuchling/50-examples/blob/master/gravity.rst

"""

import math
import pandas as pd
from time import process_time
import os
import sys
from dask.distributed import Client

#Set the global constants
G = 6.67428e-11           # The gravitational constant G
AU = (149.6e6 * 1000)     # 149.6 million km, in meters.
SCALE = 250 / AU

##Check and set the correct/current directory
print("Current working directory -" , os.getcwd())


##Read in the data from the current directory
#List of datasets with bodies for the simulation
#infile = "object_list_planets.csv"
#infile = "object_list_38_objects.csv"
infile = "object_list_500_objects.csv"
#infile = "object_list_1000_objects.csv"
#infile = "object_list_2000_objects.csv"
#infile = "object_list_4000_objects.csv"
#infile = "object_list_8000_objects.csv"

#XSEDE Python module doesn't have permission to permission to access the 
#directory where the CSV file is located
if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
    csv_path = sys.argv[1]
else:
    csv_path = "C:/"+ infile
    
#data = pd.read_csv("object_list-*-*.csv", index_col=0, dtype={ "name":str, "mass":float, "px":float, "py":float, "vx":float, "vy":float, "total_fx":float, "total_fy":float}
init_df = pd.read_csv(csv_path, encoding='utf-8', dtype={ "name":str, "mass":float, "px":float, "py":float, "vx":float, "vy": float, "total_fx":float, "total_fy":float})
#init_df = pd.read_csv(infile, dtype={ "name":str, "mass":float, "px":float, "py":float, "vx":float, "vy": float, "total_fx":float, "total_fy":float})
init_df = init_df.set_index('index')
####Consider removing total_fx and total_fy from the df. Not needed to be written to memory
rolling_df = pd.DataFrame(columns = ['name','mass','px','py','vx','vy','step'])
##Distributed Machine
#dask.config.config
client = Client(processes = False)
#The number of threads/cores available on each worker node
#client.ncores
#processes=1 threads=12, memory=16.95 GB

#Calculates all of the forces of the other bodies on all of the bodies in the dataset
def loop_force(body, remote_df):
    parameter = remote_df.index.tolist()
    #for body in global_list_bodies:
    #Add up all of the forces exerted on 'body' from the other bodies in the simulation
    all_other_bodies = parameter[:]
    all_other_bodies.remove(body)
    total_fx = total_fy = 0.0
    for other in all_other_bodies: #Returns the force exerted upon this body by the other body.
        sx = remote_df.loc[body,'px']
        sy = remote_df.loc[body,'py']
        ox = remote_df.loc[other,'px']
        oy = remote_df.loc[other,'py']
        dx = (ox-sx)
        dy = (oy-sy)
        d2 = dx**2 + dy**2                  
        # get a ZeroDivisionError exception further down.
        if d2 == 0:
            raise ValueError("Collision between objects %r and %r"
                 % (body, other))

        # Compute the force of attraction
        f = G * remote_df.loc[body,'mass'] * remote_df.loc[other,'mass'] / d2   
        # Compute the direction of the force.
        theta = math.atan2(dy, dx)
        fx = math.cos(theta) * f
        fy = math.sin(theta) * f 
        #fx, fy = attraction(body, other)
        total_fx += fx
        total_fy += fy
    #Record the total force exerted.
    return total_fx, total_fy, remote_df.loc[body,'mass'], body      

#Function that works with output with delay output for force calculations   
def move_body(result_tuple, test_df):
    timestep = 24*3600  # One day in seconds
    #Update velocities and positions based upon on the force.
    #vx|y delta = Calculated total_forcex|y from other bodies  / mass * timestep
    vx = result_tuple[0] / result_tuple[2] * timestep
    #vx|y on record = last vx|y + delta vx|y. Note: Dask doesn't like += and -= so that's why this is split into two lines
    test_df.loc[result_tuple[3],'vx'] = test_df.loc[result_tuple[3],'vx'] + vx
    vy = result_tuple[1]  / result_tuple[2] * timestep
    test_df.loc[result_tuple[3],'vy'] = test_df.loc[result_tuple[3],'vy'] + vy
    px = test_df.loc[result_tuple[3],'vx'] * timestep
    test_df.loc[result_tuple[3],'px'] = test_df.loc[result_tuple[3],'px'] + px
    py = test_df.loc[result_tuple[3],'vy'] * timestep
    test_df.loc[result_tuple[3],'py'] = test_df.loc[result_tuple[3],'py'] + py
    return result_tuple[3], result_tuple[2], test_df.loc[result_tuple[3],'px'], test_df.loc[result_tuple[3],'py'], test_df.loc[result_tuple[3],'vx'], test_df.loc[result_tuple[3],'vy']

    
#Runs the simulation

#More global variables for the functions

#Don't delete init_df or it will delete remote_df
##%%time
start_time = process_time()
def main():
    step = 0
    planet_checklist = ["Sun","Mercury","Venus","Earth", "Mars", "Jupiter", "Saturn","Uranus","Neptune", "Pluto"]
    
    global_list_bodies = init_df.index.tolist()
    remote_df = client.scatter(init_df.loc[:,'mass':'vy'], broadcast=True) #Send data to all workers
    while step <= 370:
        futures = client.map(loop_force,global_list_bodies,[remote_df for i in global_list_bodies])
        results = client.gather(futures)
        #Every parameter submitted to map() must be iterable. So for every body send a copy of the dataset
        #Pass list comprehension of the df to ensure a copy is submitted with each body.
        #Option to pass workers=  argument ; providing a hostname, IP address, or alias   
        move_futures = client.map(move_body,results,[remote_df for i in results])
        move_results = client.gather(move_futures)
        #Update data in memory and resend to workers for the next loop
        remote_df = pd.DataFrame(list(move_results), columns =['name','mass','px','py','vx','vy']).set_index('name', drop=False)
        if step==370:
            append_step = remote_df.loc[planet_checklist,'name':'vy']
            append_step["step"] = step
            print("Saving Future Results to Memory")
            append_step.to_csv('/env/'+str(step)+'th_step_results_'+str(len(remote_df))+'bodies_future.csv')
        remote_df = client.scatter(remote_df, broadcast=True) 
        step += 1
    print("Time of the simulation", process_time()-start_time, " seconds")

if __name__ == "__main__":
    main()
#client.cancel(move_result)
#client.shutdown()

"""
Works Referenced
https://www.geeksforgeeks.org/different-ways-to-create-pandas-dataframe/
https://docs.python.org/3/library/time.html#time.perf_counter
https://docs.python.org/2/library/timeit.html
https://www.programcreek.com/python/example/84234/time.process_time
https://stackoverflow.com/questions/19951816/python-changes-to-my-copy-variable-affect-the-original-variable
http://www.scholarpedia.org/article/N-body_simulations
https://docs.dask.org/en/latest/dataframe-api.html
https://stackoverflow.com/questions/44602766/unpacking-result-of-delayed-function
https://stackoverflow.com/questions/48728383/dask-delayed-object-of-unspecified-length-not-iterable-error-when-combining-dict
https://examples.dask.org/applications/embarrassingly-parallel.html
https://docs.google.com/presentation/d/1hcgwy6S7QXVCIZHI0_Rb7_9FPHQP8HH6iWmaqCKpdIU/edit#slide=id.g4011a25655_0_15/https://www.sdsc.edu/education_and_training/training/201905_distributed_parallel_computing_with_python.html
https://docs.dask.org/en/latest/delayed-best-practices.html#avoid-calling-delayed-within-delayed-functions #Very helpful
https://docs.dask.org/en/latest/delayed-api.html
https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/
https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/


Dask Library Reference
https://distributed.dask.org/en/latest/client.html
https://distributed.dask.org/en/latest/quickstart.html
https://docs.dask.org/en/latest/
https://docs.dask.org/en/latest/setup.html
https://distributed.dask.org/en/latest/locality.html



Data
https://ssd.jpl.nasa.gov/sbdb_query.cgi#x
https://nssdc.gsfc.nasa.gov/planetary/factsheet/asteroidfact.html
https://ssd.jpl.nasa.gov/horizons.cgi


Methodologies
https://docs.dask.org/en/latest/
https://docs.rapids.ai/api/cudf/stable/10min.html
https://github.com/classner/pymp
https://docs.python.org/2/library/multiprocessing.html#using-a-pool-of-workers
https://stackoverflow.com/questions/33480675/multiprocessing-on-a-set-number-of-cores



 for batch in as_completed(futures, with_results = True).batches():
        batch_results = client.gather(batch)
        batch_two = client.gather(futures.next_batch())

 for future, result in as_completed(futures,with_results = True):
        #results = client.gather(batch)#Returns the body parameters needed for the move function as they complete
        move_result = client.submit(move_body,result,remote_df) #remote_df is a dask object that can't be indexed, so pass it to map like before

#for batch in as_completed(futures).batches():
        #results = client.gather(batch) #Returns the body parameters needed for the move function as they complete
        ###Losing 2 to 3 futures in the batches. Bodies are being dropped from the remote df index
"""
