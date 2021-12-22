import pandas as pd
import re
import os

# Helper functions

# Get a list of column ranges according to the type of schema
def get_col_spec_list( schema_df ):
    schema_df[ 'CharPosEnd' ] = schema_df[ 'Length' ].cumsum()
    schema_df[ 'CharPosStart' ] = ( schema_df.shift( periods = 1, fill_value = 0 ) )[ 'CharPosEnd' ]
    schema_df.loc[ schema_df[ 'Field' ] == 'PTS', 'CharPosStart' ] = 0
    
    colspecs = [ ( CharPosStart, CharPosEnd ) for CharPosStart, CharPosEnd in zip( schema_df[ 'CharPosStart' ], schema_df[ 'CharPosEnd' ] ) ]
    
    return colspecs

# Get a df that classifies each row in the file as each type of finwire file
def get_finwire_row_types( finwire_df ):
    finwire_type_df = pd.read_fwf( finwire_df, [( 15, 18 )], header = None )
    finwire_type_df.columns = [ 'Type' ]
    finwire_type_df[ 'RowID' ] = finwire_type_df.index
    return finwire_type_df

# Get a list of rows to exclude to keep rows the desired finwire type
def get_finwire_rows_to_exclude( finwire_df, finwire_type ):
    if( finwire_type == 'CMP' ):
        finwire_df = finwire_df[ finwire_df.Type != 'CMP' ] 
    elif( finwire_type == 'SEC' ):
        finwire_df = finwire_df[ finwire_df.Type != 'SEC' ] 
    elif( finwire_type == 'FIN' ):
        finwire_df = finwire_df[ finwire_df.Type != 'FIN' ] 
        
    return [ RowID for RowID in finwire_df[ 'RowID' ] ]

# Get the finwire file parsed for a particular finwire type
def get_finwire_df_for_type( finwire_file_path, finwire_type, schema_df ):
    row_types_df = get_finwire_row_types( finwire_file_path )
    
    if( finwire_type == 'CMP' ):
        rows_excluded = get_finwire_rows_to_exclude( row_types_df, 'CMP' )
        df = pd.read_fwf( finwire_file_path, get_col_spec_list( schema_df ), header = None, skiprows = rows_excluded )
    elif( finwire_type == 'SEC' ):
        rows_excluded = get_finwire_rows_to_exclude( row_types_df, 'SEC' )
        df = pd.read_fwf( finwire_file_path, get_col_spec_list( schema_df ), header = None, skiprows = rows_excluded  )
    elif( finwire_type == 'FIN' ):
        rows_excluded = get_finwire_rows_to_exclude( row_types_df, 'FIN' )
        df = pd.read_fwf( finwire_file_path, get_col_spec_list( schema_df ), header = None, skiprows = rows_excluded  )

    df.columns = [ col_name for col_name in schema_df[ 'Field' ] ]

    return df        
       
# Scan a finwire file and return a dictionary with each of its finwire types dataframes 
def parse_finwire_data( finwire_file_path ):
    row_types_df = get_finwire_row_types( finwire_file_path )
    row_types = list( row_types_df[ 'Type' ].drop_duplicates() )
    finwire_dfs = { 'CMP': None, 'SEC': None, 'FIN': None }
    
    for row_type in row_types:
        if( row_type == 'CMP' ):
            finwire_dfs[ 'CMP' ] = get_finwire_df_for_type( finwire_file_path, 'CMP', cmp_schema_df )
        elif( row_type == 'SEC' ):
            finwire_dfs[ 'SEC' ] = get_finwire_df_for_type( finwire_file_path, 'SEC', sec_schema_df )
        elif( row_type == 'FIN' ):
            finwire_dfs[ 'FIN' ] = get_finwire_df_for_type( finwire_file_path, 'FIN', fin_schema_df )
            
    return finwire_dfs

# Parse a list of finwire files and return each as a collection of finwire type dataframes
def get_finwire_dfs( finwire_file_paths ):
    cmp_df = pd.DataFrame()
    sec_df = pd.DataFrame()
    fin_df = pd.DataFrame()
    
    for file_path in finwire_file_paths:
        finwire_df_dict = parse_finwire_data( file_path )
        
        for finwire_type in finwire_df_dict.keys():
            if( finwire_type == 'CMP' ):
                cmp_df = cmp_df.append( finwire_df_dict[ 'CMP' ] )
            elif( finwire_type == 'SEC' ):
                sec_df = sec_df.append( finwire_df_dict[ 'SEC' ] )
            elif( finwire_type == 'FIN' ):
                fin_df = fin_df.append( finwire_df_dict[ 'FIN' ] )
                
    return { 'CMP': cmp_df, 'SEC': sec_df, 'FIN': fin_df }
        
    
# Define file paths
root_path = r'E:\OneDrive - Université Libre de Bruxelles\Mes fichiers\419-SQLServerBenchmark Project\TPC-DI'
finwire_source_files_path = root_path + r'\Data\SF20\Batch1'
finwire_schema_files_path = root_path + r'\Helpers\Datasets'

# Read the schema dataframes
cmp_schema_df = pd.read_csv( finwire_schema_files_path + '\CMP_Records_Schema.csv' )
fin_schema_df = pd.read_csv( finwire_schema_files_path + '\FIN_Records_Schema.csv' )
sec_schema_df = pd.read_csv( finwire_schema_files_path + '\SEC_Records_Schema.csv' )

# Get the column specifications from the schema dataframes
cmp_colspecs = get_col_spec_list( cmp_schema_df )
fin_colspecs = get_col_spec_list( fin_schema_df )
sec_colspecs = get_col_spec_list( sec_schema_df )

# Search for all the finwire files
finwire_files = [ finwire_source_files_path + '\\' + file for file in os.listdir( finwire_source_files_path ) if re.search( r'^FINWIRE......$', file ) ]
g = get_finwire_dfs( finwire_files )

g[ 'CMP' ]['FoundingDate'] = g[ 'CMP' ]['FoundingDate'].astype(pd.Int64Dtype())
        
g[ 'CMP' ].to_csv( finwire_source_files_path + r'\{0}.csv'.format( 'CMP' ), index=None )
g[ 'FIN' ].to_csv( finwire_source_files_path + r'\{0}.csv'.format( 'FIN' ), index=None )
g[ 'SEC' ].to_csv( finwire_source_files_path + r'\{0}.csv'.format( 'SEC' ), index=None )

# for key in g.keys():
#     df = g[ key ]
   
#     for c in df.columns:
#         print( key, c, df[ c ].astype( 'str' ).str.len().max() )
#         print()

