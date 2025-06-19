from createInputAlphafold3.cli import parse_args
from createInputAlphafold3.createLauncher import create_launcher
from createInputAlphafold3.list import display_json
from createInputAlphafold3.merge import (
    create_json_params,
    load_sample_plan,
    create_json
)


def main() -> None:
    """
    Point d'entrée principal de l'application jsonCreator.
    Exécute la commande demandée : list, merge ou launcher.
    """
    args = parse_args()

    if args.command == "list":
        display_json(args.directory)

    elif args.command == "merge":
        if args.protein is None and args.sample_plan is None:
            raise TypeError("You must provide either --protein or samplePlan file")

        if args.sample_plan:
            protein_groups = load_sample_plan(args.sample_plan)
            for proteins in protein_groups:
                name = create_json(proteins, args.seeds, args.input, args.output)
                create_json_params(name, args.output, args.model_dir, args.server_path)

        # Optionnel : à implémenter si support des --protein sans plan
        elif args.protein:
            raise NotImplementedError("--protein option is not yet implemented.")

    elif args.command == "launcher":
        create_launcher(args.input, args.server_path, args.nextflow_path, args.output)


if __name__ == "__main__":
    main()
