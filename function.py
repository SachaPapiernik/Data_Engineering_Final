import pandas as pd
import numpy as np
from unidecode import unidecode

def sanitize_column_names(df: pd.DataFrame) -> pd.DataFrame:
    """
    Sanitize DataFrame column names by replacing spaces and special characters.

    Parameters:
    df (pd.DataFrame): The DataFrame whose columns need to be sanitized.

    Returns:
    pd.DataFrame: DataFrame with sanitized column names.
    """
    df.columns = [
        unidecode(col)
        .replace(' ', '_')
        .replace('%', 'Percent')
        .replace('/', '_')
        for col in df.columns
    ]
    return df

def convert_percentage_to_float(value: any) -> any:
    """
    Convert percentage strings to float.

    Parameters:
    value (any): The value to convert, typically a string containing a percentage.

    Returns:
    any: The converted float value or the original value if not a percentage string.
    """
    if isinstance(value, str) and '%' in value:
        return float(value.replace('%', '').replace(',', '.'))
    return value

def get_2024() -> pd.DataFrame:
    """
    Get and process the 2024 election data.

    Returns:
    pd.DataFrame: Processed DataFrame for the 2024 election.
    """

    url = 'https://www.data.gouv.fr/fr/datasets/r/27345cbc-7e49-4050-8cfc-be3ad1865890'

    df = pd.read_excel(url)

    df['Libellé circonscription législative'] = df['Libellé circonscription législative'].str.replace("è","e")

    df = pd.wide_to_long(df, 
                            stubnames=['Numéro de panneau', 'Nuance candidat', 'Nom candidat', 'Prénom candidat', 'Sexe candidat', 'Voix', '% Voix/inscrits', '% Voix/exprimés', 'Elu'], 
                            i=['Code département', 'Libellé département', 'Code circonscription législative', 'Libellé circonscription législative', 'Inscrits', 'Votants', '% Votants', 'Abstentions', '% Abstentions', 'Exprimés', '% Exprimés/inscrits', '% Exprimés/votants', 'Blancs', '% Blancs/inscrits', '% Blancs/votants', 'Nuls', '% Nuls/inscrits', '% Nuls/votants'], 
                            j='Candidate Number', 
                            sep=' ').reset_index()

    df['Elu'] = df['Elu'].fillna(0)

    df = df.dropna(axis=0)

    return df

def get_2022(df_2024_circo: pd.DataFrame) -> pd.DataFrame:
    """
    Get and process the 2022 election data.

    Parameters:
    df_2024_circo (pd.DataFrame): DataFrame containing 2024 circo data for merging.

    Returns:
    pd.DataFrame: Processed DataFrame for the 2022 election.
    """

    url = "https://www.data.gouv.fr/fr/datasets/r/33705a8a-7024-4311-a3f9-988063b0e10e"

    df = pd.read_excel(url)

    df = df.drop(['Etat saisie','Code de la circonscription'],axis=1)
    
    df['Libellé de la circonscription'] = df['Libellé de la circonscription'].str.replace("è","e")

    df = pd.merge(left=df_2024_circo,
                  right=df,
                  left_on=["Libellé département",'Libellé circonscription législative'],
                  right_on=['Libellé du département','Libellé de la circonscription']).drop(['Libellé du département',
                                                                                             'Libellé de la circonscription']
                                                                                            ,axis=1)

    column_mapping = {
        'Code du département': 'Code département',
        'Libellé du département': 'Libellé département',
        'Code de la circonscription': 'Code circonscription législative',
        'Libellé de la circonscription': 'Libellé circonscription législative',
        '% Vot/Ins': '% Votants',
        '% Abs/Ins': '% Abstentions',
        '% Exp/Ins': '% Exprimés/inscrits',
        '% Exp/Vot': '% Exprimés/votants',
        '% Blancs/Ins': '% Blancs/inscrits',
        '% Blancs/Vot': '% Blancs/votants',
        '% Nuls/Ins': '% Nuls/inscrits',
        '% Nuls/Vot': '% Nuls/votants',
        'Candidate': 'Candidate Number',
        'N°Panneau': 'Numéro de panneau',
        'Nuance': 'Nuance candidat',
        'Nom': 'Nom candidat',
        'Prénom': 'Prénom candidat',
        'Sexe': 'Sexe candidat',
        '% Voix/Ins': '% Voix/inscrits',
        '% Voix/Exp': '% Voix/exprimés',
        'Sièges': 'Elu'
    }

    df = df.rename(columns = column_mapping)

    df['Unnamed: 216'] = np.nan

    base = list(df.columns[:18])

    base_list = ['Numéro de panneau', 'Sexe candidat', 'Nom candidat', 'Prénom candidat','Nuance candidat', 'Voix', '% Voix/inscrits', '% Voix/exprimés', 'Elu']

    # Generate the list 22 times with numbering from 1 to 22
    repeated_lists = [f'{item} {i}' for i in range(1, 23) for item in base_list]

    df.columns = (base + repeated_lists)

    df = pd.wide_to_long(df, 
                    stubnames=base_list, 
                    i=['Code département', 'Libellé département', 'Code circonscription législative', 'Libellé circonscription législative', 'Inscrits', 'Abstentions', '% Abstentions', 'Votants', '% Votants', 'Blancs', '% Blancs/inscrits', '% Blancs/votants', 'Nuls', '% Nuls/inscrits', '% Nuls/votants', 'Exprimés', '% Exprimés/inscrits', '% Exprimés/votants'], 
                    j='Candidate Number', sep=' ').reset_index()


    df['Elu'] = df['Elu'].fillna(0)

    df = df.dropna(axis=0)

    return df

def create_df() -> tuple:
    """
    Create DataFrames for the 2024 and 2022 election data.

    Returns:
    tuple: Tuple containing three DataFrames: circo_table, circo_data, circo_candidate_data.
    """

    df_2024 = get_2024()

    df_2024.map(convert_percentage_to_float)
    
    circo_table = df_2024[['Code département', 'Libellé département','Code circonscription législative','Libellé circonscription législative']].drop_duplicates()

    circo_data_2024 = df_2024[['Code circonscription législative', 'Inscrits', 'Votants',
            '% Votants', 'Abstentions', '% Abstentions', 'Exprimés',
            '% Exprimés/inscrits', '% Exprimés/votants', 'Blancs',
            '% Blancs/inscrits', '% Blancs/votants', 'Nuls', '% Nuls/inscrits',
            '% Nuls/votants']].drop_duplicates()

    circo_candidate_data_2024 = df_2024[['Code circonscription législative', 'Candidate Number', 'Numéro de panneau',
            'Nuance candidat', 'Nom candidat', 'Prénom candidat', 'Sexe candidat',
            'Voix', '% Voix/inscrits', '% Voix/exprimés', 'Elu']]

    circo_candidate_data_2024.loc[:, 'Sexe candidat'] = circo_candidate_data_2024['Sexe candidat'].replace({'MASCULIN': 'M', 'FEMININ': 'F'})


    df_2022 = get_2022(df_2024_circo = circo_table[['Libellé département', 'Code circonscription législative', 'Libellé circonscription législative']])

    circo_data_2022 = df_2022[['Code circonscription législative', 'Inscrits', 'Votants',
            '% Votants', 'Abstentions', '% Abstentions', 'Exprimés',
            '% Exprimés/inscrits', '% Exprimés/votants', 'Blancs',
            '% Blancs/inscrits', '% Blancs/votants', 'Nuls', '% Nuls/inscrits',
            '% Nuls/votants']].drop_duplicates()

    circo_candidate_data_2022 = df_2022[['Code circonscription législative', 'Candidate Number', 'Numéro de panneau',
            'Nuance candidat', 'Nom candidat', 'Prénom candidat', 'Sexe candidat',
            'Voix', '% Voix/inscrits', '% Voix/exprimés', 'Elu']]
    
    circo_candidate_data_2022 = circo_candidate_data_2022.copy()
    circo_candidate_data_2024 = circo_candidate_data_2024.copy()


    circo_data_2022.loc[:, 'year'] = 2022
    circo_data_2024.loc[:, 'year'] = 2024

    circo_candidate_data_2024.loc[:, 'year'] = 2022
    circo_candidate_data_2022.loc[:, 'year'] = 2024

    circo_data = pd.concat([circo_data_2022, circo_data_2024], ignore_index=True)
    circo_candidate_data = pd.concat([circo_candidate_data_2022, circo_candidate_data_2024], ignore_index=True)


    circo_table = sanitize_column_names(circo_table)
    circo_data = sanitize_column_names(circo_data)
    circo_candidate_data = sanitize_column_names(circo_candidate_data)

    return circo_table, circo_data, circo_candidate_data