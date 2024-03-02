import _ from "lodash";

export function tableSortReducer(state, action) {
  switch (action.type) {
    case "UPDATE_DATA":
      return {
        column: action.column,
        data: action.data,
        direction: action.direction,
      };
    case "CHANGE_SORT":
      if (state.column === action.column) {
        return {
          ...state,
          data: state.data.slice().reverse(),
          direction:
            state.direction === "ascending" ? "descending" : "ascending",
        };
      }
      return {
        column: action.column,
        data: _.sortBy(state.data, [action.column]),
        direction: "ascending",
      };
    default:
      throw new Error();
  }
}
