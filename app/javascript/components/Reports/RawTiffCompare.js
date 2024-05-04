import React, { useState, useEffect, useRef, Fragment } from "react";
import {
  Button,
  Label,
  Divider,
  Form,
  Breadcrumb,
  Table,
  Icon,
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

const RawTiffCompare = ({ projects, token }) => {
  const [message, setMessage] = useState(null);
  const [submitted, setSubmitted] = useState(false);
  const [result, setResult] = useState(null);

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: result || [],
    direction: null,
  });
  const { column, data, direction } = state;

  const {
    handleSubmit,
    reset,
    setValue,
    getValues,
    control,
    formState: { errors },
  } = useForm({
    defaultValues: {
      project: projects[0],
    },
  });

  console.log("TotalDelivery", {
    result,
    values: getValues(),
    errors,
  });

  useEffect(() => {
    if (result) {
      dispatch({
        data: result,
        type: "UPDATE_DATA",
      });
    }
  }, [result]);

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const resetForm = () => {
    reset();
    setResult(null);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);

    const obj = {
      authenticity_token: token,
      project: data.project,
      input_directory: data.input_directory,
      flight_date: moment(data.flight_date, "l").format("YYYY-MM-DD"),
    };

    axios.post(`/raw_tiff_compare/execute`, obj).then(({ data }) => {
      console.log("submit response", data);

      if (data.pass) {
        // setMessage({
        //   status: "Success",
        //   text: data.message,
        // });
        setResult(data.result);
      } else {
        setMessage({
          status: "Error",
          text: data.message ? data.message : "Something went wrong",
        });
      }

      setTimeout(() => {
        setSubmitted(false);
      }, 1000);
    });
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Raw Tiff Compare</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {message && (
        <MessageBox
          status={message.status}
          title={message.title}
          message={message.text}
        />
      )}
      {renderForm()}
      {renderTable()}
    </div>
  );

  function renderIcon(bool) {
    if (bool === true) {
      return (
        <Icon
          size="large"
          name="checkmark"
          color="green"
          style={{ verticalAlign: "middle !important" }}
        />
      );
    } else if (bool === false) {
      return (
        <Icon
          size="large"
          name="remove"
          color="red"
          style={{ verticalAlign: "middle !important" }}
        />
      );
    } else {
      return "-";
    }
  }

  function renderForm() {
    return (
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                label={"Project"}
                required={true}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                  };
                })}
                error={
                  errors["project"]
                    ? {
                        content: errors["project"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />

          <Form.Field error={errors.hasOwnProperty("flight_date")}>
            <div className="calendar-input">
              <Controller
                name={"flight_date"}
                control={control}
                rules={{
                  required: "Required",
                }}
                render={({ field: { name, value, defaultValue } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Flight Date"}
                    required={true}
                    value={value || ""}
                    dateFormat="MM/DD/YYYY"
                    iconPosition="left"
                    onChange={handleChange}
                    autoComplete="off"
                  />
                )}
              />
            </div>
            {errors[`flight_date`] && (
              <Label pointing prompt>
                {errors[`flight_date`].message}
              </Label>
            )}
          </Form.Field>
        </Form.Group>
        <Form.Group widths="equal">
          <Controller
            name={"input_directory"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                label={`Directory to Raw Tiffs`}
                autoComplete="off"
                name={name}
                required={true}
                onBlur={onBlur}
                onChange={onChange}
                value={value || ""}
                error={
                  errors["input_directory"] && errors["input_directory"].message
                }
              />
            )}
          />
        </Form.Group>

        <Divider />

        <Button
          primary
          loading={submitted}
          disabled={submitted}
          floated="right"
          type="button"
          onClick={handleSubmit(onSubmit)}
        >
          Submit
        </Button>
        <Button
          secondary
          disabled={submitted}
          floated="right"
          type="button"
          onClick={() => resetForm()}
        >
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }

  function renderTable() {
    if (submitted) {
      return <MessageBox status={"Loading"} title={"Iterating Files.."} />;
    }

    if (data.length === 0) return null;

    return (
      <div className="table-overflow" style={{ padding: "2em 0 4em" }}>
        <Table
          selectable
          unstackable
          sortable
          celled
          striped
          style={{ textAlign: "center" }}
        >
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                sorted={column === "strip_frame" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "strip_frame" })
                }
              >
                Strip Frame
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "state_abv" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "state_abv" })
                }
              >
                State
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "county_name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "county_name" })
                }
              >
                County
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "utm_zone" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "utm_zone" })
                }
              >
                UTM Zone
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "has_tiles" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "has_tiles" })
                }
              >
                Has Tile?
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "has_rfp" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "has_rfp" })
                }
              >
                Rejected?
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "no_sun_angle" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "no_sun_angle" })
                }
              >
                No Sun Angle Errors?
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {data.map((record, index) => {
              if (record.state_abv === null) {
                return (
                  <Table.Row style={{ cursor: "pointer" }} key={index}>
                    <Table.Cell>{record.strip_frame}</Table.Cell>
                    <Table.Cell colSpan="6">
                      No Footprint found in app
                    </Table.Cell>
                  </Table.Row>
                );
              } else {
                return (
                  <Table.Row style={{ cursor: "pointer" }} key={index}>
                    <Table.Cell>{record.strip_frame}</Table.Cell>
                    <Table.Cell>{record.state_abv}</Table.Cell>
                    <Table.Cell>{record.county_name}</Table.Cell>
                    <Table.Cell>{record.utm_zone}</Table.Cell>
                    <Table.Cell>{renderIcon(record.has_tiles)}</Table.Cell>
                    <Table.Cell>{renderIcon(record.has_rfp)}</Table.Cell>
                    <Table.Cell>{renderIcon(record.no_sun_angle)}</Table.Cell>
                  </Table.Row>
                );
              }
            })}
          </Table.Body>
        </Table>
      </div>
    );
  }
};

export default RawTiffCompare;
